require 'detective.rb'
require 'mediawiki_api.rb'
require 'time'
require 'sqlite3'
require 'bundler/setup'
require 'nokogiri'

class PageDetective < Detective
  def self.table_name
    'page'
  end

  #return a proc that defines the columns used by this detective
  #if using this as an example, you probably should copy the first two columns (the id and foreign key)
  def self.columns
    Proc.new do
      <<-SQL
      id integer primary key autoincrement,
      revision_id integer,                                 --foreign key to reference the original revision
      page_last_revision_id integer,
      page_last_revision_time timestamp(20),               --time of last revision on this page
      --popularity TODO!
      page_text text,
      --protection string,
      length integer,
      num_views integer,
      talk_id integer,
      page_id integer,
      tags string,
      created DATE DEFAULT (datetime('now','localtime'))
      --FOREIGN KEY(revision_id) REFERENCES irc_wikimedia_org_en_wikipedia(revision_id)   --TODO this table name probably shouldn't be hard coded
SQL
    end
  end

  #info is a list:
  # 0: article_name (string),
  # 1: desc (string),
  # 2: rev_id (string),
  # 3: old_id (string)
  # 4: user (string),
  # 5: byte_diff (int),
  # 6: description (string)
  # 7: diff_unescaped_xml (string)
  # 8: attributes from call: user, timestamp, revid, size, title, from, to, parentid, anon, ns, space, pageid
  # 9: tags (Array)
  # 10: array of array of links found in [url, desc] format, description may be nil if it was not a wikilink
  def investigate info
    page = find_page_history(info)
    db_write!(
      ['revision_id', 'page_last_revision_id', 'page_last_revision_time', 'page_text', 'length', 'num_views', 'talk_id', 'page_id', 'tags'],
      [info[2]] + page
    )
  end

  def find_page_history info
#    #http://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=342098230&rvprop=timestamp|user|comment|content
#    xml = get_xml({:format => :xml, :action => :query, :prop => :revisions, :revids => info[2], :rvprop => 'ids|timestamp|user|comment|content'})
#    res = parse_xml(xml)
#    rev_id = '-' #this will be used if the page is newly created
#    time = ''
#    if(res.first['badrevids'] == nil)
#      rev_id = res.first['pages'].first['page'].first['revisions'].last['rev'].first['revid']
#      time = Time.parse(res.first['pages'].first['page'].first['revisions'].last['rev'].first['timestamp']).to_i
#    end -> already getting this information from below
    
    #http://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=230948209&rvprop=content
    xml = get_xml({:format => :xml, :action => :query, :prop => :revisions, :revids => info[2], :rvprop => 'content'})
    res2 = parse_xml(xml)
    source = ''
    if(res2.first['badrevids'] == nil)
      source = res2.first['pages'].first['page'].first['revisions'].first['rev'].first['content'].to_s
    end   

    #http://en.wikipedia.org/w/api.php?action=query&titles=Albert%20Einstein&prop=info&inprop=protection|talkid
    xml = get_xml({:format => :xml, :action => :query, :revids => info[2], :prop => :info, :inprop => 'protection|talkid'})
    res3 = parse_xml(xml)
    num_views, length, touched, last_revid, talk_id, page_id = nil
    if(res3.first['badrevids'] == nil)
      num_views = res3.first['pages'].first['page'].first['counter'].to_i
      length = res3.first['pages'].first['page'].first['length'].to_i
      touched = Time.parse(res3.first['pages'].first['page'].first['touched']).to_i
      last_revid = res3.first['pages'].first['page'].first['lastrevid'].to_i
      talk_id = res3.first['pages'].first['page'].first['talkid'].to_i
      page_id = res3.first['pages'].first['page'].first['pageid'].to_i
    end

    if (info[8])
      tags = info[8]["tags"]
    end
    #Need to encode this into a string using sqlite method or serialize it somehow
    #puts encode(res3.first['pages'].first['page'].first['protection'])
    #TODO: get protection
    [last_revid, touched, source, length, num_views, talk_id, page_id, tags]
  end  
end