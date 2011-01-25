require 'detective.rb'
require 'mediawiki_api.rb'
require 'uri'
require 'net/http'

class ExternalLinkDetective < Detective
  def table_name
    'link'
  end

  #return a proc that defines the columns used by this detective
  #if using this as an example, you probably should copy the first two columns (the id and foreign key)
  def columns
    Proc.new do
      <<-SQL
      id integer primary key autoincrement,
      revision_id integer,                              --foreign key to reference the original revision
      link string,
      source text,
      screenshot text,
      FOREIGN KEY(revision_id) REFERENCES irc_wikimedia_org_en_wikipedia(id)   --TODO this table name probably shouldnt be hard coded
SQL
    end
  end

  #info is a list: 
  # 0: sample_id (string), 
  # 1: article_name (string), 
  # 2: desc (string), 
  # 3: rev_id (string),
  # 4: old_id (string)
  # 5: user (string), 
  # 6: byte_diff (int), 
  # 7: timestamp (Time object), 
  # 8: description (string)
  def investigate info
        
    linkarray = find_link_info(info)
    
    rownum = 0
    linkarray.each do |linkentry|
      rownum = db_write!(
        ['revision_id', 'link', 'source', 'screenshot'],
	      [info[0], linkentry["link"], linkentry["source"], linkentry['screenshot']]
	    )
    end	
    rownum
  end	
  
  def find_link_info info
    #this is actually 'page' stuff
    #take popularity from: http://www.trendingtopics.org/page/[article_name]; links to csv's with daily and hourly popularity
    #http://stats.grok.se/en/top <- lists top pages
    #http://stats.grok.se/en/[year][month]/[article_name]
    #also http://toolserver.org/~emw/wikistats/?p1=Barack_Obama&project1=en&from=12/10/2007&to=12/11/2010&plot=1
    #http://wikitech.wikimedia.org/view/Main_Page
    #http://lists.wikimedia.org/pipermail/wikitech-l/2007-December/035435.html
    #http://wiki.wikked.net/wiki/Wikimedia_statistics/Daily
    #http://aws.amazon.com/datasets/Encyclopedic/4182
    #https://github.com/datawrangling/trendingtopics

    #link popularity/safety stuff:
    #http://code.google.com/apis/safebrowsing/
    #http://groups.google.com/group/google-safe-browsing-api/browse_thread/thread/b711ba69a4ecbb2f/29aa959a3a28a0bd?#29aa959a3a28a0bd

    #this is what we're going to do: get all external links for prev_id and all external links for curr_id and diff them, any added => new extrnal links to find
    #http://en.wikipedia.org/w/api.php?action=query&prop=extlinks&revids=800129
    xml= get_xml({:format => :xml, :action => :query, :prop => :extlinks, :revids => info[3]})
    res = parse_xml(xml)
    links_new = res.first['pages'].first['page'].first['extlinks']
    if(links_new!=nil)
	    links_new = links_new.first['el']
    else
	    links_new = []
    end
    links_new.collect! do |link|
      link['content']
    end

    xml= get_xml({:format => :xml, :action => :query, :prop => :extlinks, :revids => info[4]})
    res = parse_xml(xml)
    links_old = res.first['pages'].first['page'].first['extlinks']

    if(links_old!=nil)
	    links_old = links_old.first['el']
    else
	    links_old = []
    end
    links_old.collect! do |link|
      link['content']
    end

    linkdiff = links_new - links_old
    
    linkarray = []
    linkdiff.each do |link|
       response = Net::HTTP.get_response URI.parse(link)
       if(response.content_type != "text/html")
         source = ""
       else
         source = Net::HTTP.get URI.parse(link)
       end
       #TODO do a check for the size and type-content of it before we pull it
       #binary files we probably don't need to grab and things larger than a certain size we don't want to grab
       if(source.length > 10000)
         source = source[0,10000]
       end
       #not sure exactly where to store the images, probably should have their own directory
       imname = link.delete "."
       imname = imname.delete "/"
       imnaame = imname + '.jpg'
       request = "http://api1.thumbalizr.com/?url=" + link + "&width=300"
       resp2 = Net::HTTP.get_response(URI.parse(request))
       file = File.open( imname , 'wb' )
       file.write(resp2.body)
       linkarray << {"link" => link, "source" => source, "image" => imname}
    end
    linkarray
  end  

end
