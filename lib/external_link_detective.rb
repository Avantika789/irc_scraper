require 'detective.rb'
require 'mediawiki_api.rb'
require 'uri'
require 'cgi'
require 'net/http'
require 'alexa_config.rb'
require 'alexa_urlinfo.rb'
require 'base64'
require 'bundler/setup'
require 'nokogiri'

class ExternalLinkDetective < Detective
  def self.table_name
    'link'
  end

  #return a proc that defines the columns used by this detective
  #if using this as an example, you probably should copy the first two columns (the id and foreign key)
  def self.columns
    Proc.new do
      <<-SQL
      id integer primary key autoincrement,
      revision_id integer,
      link text,
      headers text,
      source text,
      description text,
      created DATE DEFAULT (datetime('now','localtime')),

      --stuff from alexa--
      title string,
      site_description string,
      online_since timestamp,
      speed_medianloadtime decimal, 
      speed_percentile decimal,
      adult_content integer,
      language_locale string,
      language_encoding string,
      links_in_count integer,
      keywords string,
      num_related_links integer,
      related_links string,

      rank integer,
      rank_delta decimal,
      reach_rank integer, 
      reach_rank_delta decimal,
      reach_permill decimal, 
      reach_permill_delta decimal,
      views_permill decimal,
      views_permill_delta decimal,
      views_rank integer,
      views_rank_delta decimal,
      views_peruser decimal, 
      views_peruser_delta decimal,

      rank_by_city string,
      rank_by_country string,

      --stuff from google malware--
      screenshot text,
      phishing text,
      malware text
      --FOREIGN KEY(revision_id) REFERENCES irc_wikimedia_org_en_wikipedia(revision_id)   --TODO this table name probably shouldnt be hard coded

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
    linkarray = info.last
    
    results = []
    linkarray.each do |arr|
      #puts arr.first
      source_content_error, headers = find_source(arr.first)
      headers_str = Marshal.dump(headers)
      #ignore binary stuff for now
      linkinfo = find_alexa_info(arr.first)
      link = arr.first
      imname = link.delete "."
      imname = imname.delete "/"
      imnaame = imname + '.jpg'
      request = "http://api1.thumbalizr.com/?url=" + link + "&width=300"
      resp2 = Net::HTTP.get_response(URI.parse(request))
      file = File.open( imname , 'wb' )
      file.write(resp2.body)
      #all of andrews malware code needs to be in the same directory as this file,
      #it doesn't run the command properly when you try to call the file with the pathname
      malware_info = find_malware_info(link)
      encoded = headers[:'content-encoding'] ? ['gzip', 'deflate', 'compress'].include?(headers[:'content-encoding'].first) : false
      
      results << { 
        :link => arr.first, 
        :source => encoded ? 'encoded' : source_content_error, 
        :description => arr.last, 
        :headers => headers_str,
        :linkinfo => linkinfo,
        :screenshot => imname,
        :phishing => malware_info[0],
        :malware => malware_info[1]
      }
    end

    results.each do |linkentry|
      db_queue(
        ['revision_id', 'link', 'source', 'description', 'headers' 'title', 'site_description', 'online_since', 'speed_medianloadtime', 'speed_percentile', 'adult_content', 'language_locale',
      'language_encoding',
      'links_in_count',
      'keywords',
      'num_related_links',
      'related_links',
      'rank',
      'rank_delta',
      'reach_rank',
      'reach_rank_delta',
      'reach_permill',
      'reach_permill_delta',
      'views_permill',
      'views_permill_delta',
      'views_rank',
      'views_rank_delta','views_peruser','views_peruser_delta',
      'rank_by_city',
      'rank_by_country' 'screenshot', 'phishing', 'malware'],
      [info[2], linkentry[:link], linkentry[:source], linkentry[:description], linkentry[:headers]] +
        linkentry[:linkinfo] +
        [linkentry[:screenshot], linkentry[:phishing], linkentry[:malware]] )
    end	
    true # :)
  end	
  
  def find_source(url)
    #TODO do a check for the size and type-content of it _before_ we pull it
    #binary files we probably don't need to grab and things larger than a certain size we don't want to grab
    #uri = URI.parse(url)# this doesn't like wikipeida urls like http://en.wikipedia.org/wiki/Herbert_McCabe|Herbert
    url_regex = /^(.*?\/\/)([^\/]*)(.*)$/x #break it up like this, we're using urls that URI doesn't parse
    #deal with links stargin with 'www', if they get entered into wikilinks like that they count!
    unless url =~ url_regex #TODO this is silly if we're just stripping it off below
      url = "http://#{url}"
    end
    parts = url.scan(url_regex)
    #p parts

    host = parts.first[1] #this should not have the protocol, it's the domain name with 
    path = parts.first[2] #this should be at least a '/' and have the entire query
    
    http = Net::HTTP.new(host)
    resp = nil
    ret = []
    begin
      #puts host + path
      resp = http.request_get(
        path.empty? ? '/' : path, #deal with no trailing slash
        'User-Agent' => 'WikipediaAntiSpamBot/0.1 (+hincapie.cis.upenn.edu)'
      )
      if(resp.is_a? Net::HTTPOK or resp.is_a? Net::HTTPFound)
        #truncate at 100K characters; not a good way to deal with size, should check the headers only
        #else set the body to the content type
        if resp.content_type == 'text/html'
          ret << resp.body[0..10**5]
        else
          ret << resp.content_type #for binary files
        end
      else
        #puts resp.class
        ret << resp.class.to_s
      end
      #shallow convert all keys to lowercased symbols
      ret << resp.to_hash.inject({}){|memo,(k,v)| memo[k.to_s.downcase.to_sym] = v; memo} #the headers

    rescue Net::HTTPBadResponse, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::ECONNREFUSED, SocketError, 
           Timeout::Error, Errno::EINVAL, EOFError, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e #Net::HTTPExceptions also?
      ret << e.class.to_s 
      ret << {}
    rescue Exception => e
      #for some reason we're not catching all errors in the bot that calls this
      # so try capturing all exotic exceptions and reclassifying them as stock exceptions

      raise Exception.new(e.to_s) 
    end
    
    ret
  end
  
def find_alexa_info(link)
      Alexa.config do |c|
          c.access_key_id = ALEXA_KEY_ID
	  c.secret_access_key = ALEXA_SECRET_KEY
      end
      linkinfo = Alexa::UrlInfo.new(:host => link)
      xml = linkinfo.connect
      linkinfo.parse_xml(xml)
       rank, rank_delta, reach_rank, reach_rank_delta, reach_permill, 
         reach_permill_delta, views_permill, views_permill_delta, views_rank,
         views_rank_delta, views_peruser, views_peruser_delt = nil
      stats = linkinfo::usage_statistics
      if stats
      	 if !stats.empty?
            if !stats.first['Rank'].empty?
                rank = stats.first['Rank']['Value']
		rank_delta = stats.first['Rank']['Delta']
            end
            if !stats.first['Reach'].empty?
	       if !stats.first['Reach']['Rank'].empty?
                reach_rank = stats.first['Reach']['Rank']['Value']
		reach_rank_delta = stats.first['Reach']['Rank']['Delta']
               end
	       if !stats.first['Reach']['PerMillion'].empty?
                reach_permill = stats.first['Reach']['PerMillion']['Value']
		rank_permill_delta = stats.first['Reach']['PerMillion']['Delta']
               end	       
	    end       
            if !stats.first['PageViews'].empty?
	       if !stats.first['PageViews']['Rank'].empty?
                views_rank = stats.first['PageViews']['Rank']['Value']
		views_rank_delta = stats.first['PageViews']['Rank']['Delta']
               end
	       if !stats.first['PageViews']['PerMillion'].empty?
                views_permill = stats.first['PageViews']['PerMillion']['Value']
		views_permill_delta = stats.first['PageViews']['PerMillion']['Delta']
	       end
	       if !stats.first['PageViews']['PerUser'].empty?
                views_peruser = stats.first['PageViews']['PerUser']['Value']
		views_peruser_delta = stats.first['PageViews']['PerUser']['Delta']
               end	       
	    end      
         end
      end
      
      if linkinfo::adult_content == "no"
         ac = 0
      else
         ac = 1
      end

      [linkinfo::site_title.to_s, linkinfo::site_description.to_s, Time.parse(linkinfo::online_since).to_i, linkinfo::speed_median_load_time.to_f, linkinfo::speed_percentile.to_f, ac, linkinfo::language_locale.to_s, linkinfo::language_encoding.to_s, linkinfo::links_in_count.to_i, Base64.encode64(Marshal.dump(linkinfo::keywords)), linkinfo::related_links.size.to_i, Base64.encode64(Marshal.dump(linkinfo::related_links)), rank.to_i, rank_delta.to_f, reach_rank.to_i, reach_rank_delta.to_f, reach_permill.to_f, reach_permill_delta.to_f, views_permill.to_f, views_permill_delta.to_f, views_rank.to_i, views_rank_delta.to_f, views_peruser.to_f, views_peruser_delta.to_f, Base64.encode64(Marshal.dump(linkinfo::rank_by_city)), Base64.encode64(Marshal.dump(linkinfo::rank_by_country))]
  end

  def find_malware_info(link)
       sbinfo = `java test #{link}`
       sbinfo = sbinfo.chomp
       sbarr = sbinfo.partition(",")
       [sbarr[0],sbarr[2]]
  end
end
