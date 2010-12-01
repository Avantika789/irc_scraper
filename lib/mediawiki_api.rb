require 'uri'
require 'net/http'
require 'rubygems'
require 'xmlsimple'

# This function returns xml from Wikipedia's English installation API. 
# 
# params should be a hash.
def get_xml(params = {:format => :xml, :action => :query})#TODO put these in so that they're default and not lost when we pass stuff in...
  url = _form_url(params)
  
  #requests without user-agents are refused. See:
  #http://www.mooduino.co.uk/2010/04/wikipedia-api-user-agent-string-in-php.html
  http = Net::HTTP.new(WIKI_API_SERVER) #en.wikipedia.org
  resp = http.request_get(WIKI_API_PATH+url, 'User-Agent' => 'WikipediaSpamBot/0.1 (+hincapie.cis.upenn.edu)')
  
  raise "POST FAILED:" + resp.inspect unless resp.is_a? Net::HTTPOK or resp.is_a? Net::HTTPFound
  resp.body #get xml
end

#helper function to form the parameters of the get request
def _form_url(params)
  #implode params to concat 
  url = '?'
  params.each do |key, value|
    #val = URI.escape(unsafe_variable, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    url += key.to_s + '=' + value.to_s + '&'
  end
  url
end

# This function parses the xml response from Wikipedia. If given the XMl, it will return a native ruby list of the structure.
def parse_xml(xml)
  hash = XmlSimple.xml_in(xml)
  hash['query']#return just the results of the query
end
