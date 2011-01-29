require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'revision_detective.rb'

require 'time'

class RevisionDetectiveTest < Test::Unit::TestCase
  def setup
    @db = SQLite3::Database.new(":memory:")
    @db.execute('CREATE TABLE irc_wikimedia_org_en_wikipedia (
      id integer primary key autoincrement,
      article_name varchar(128) not null,
      desc varchar(8),
      revision_id integer,
      old_id integer,
      user varchar(64),
      byte_diff integer,
      ts timestamp(20),
      description text)')
    @clazz = RevisionDetective
    @queue = []
    @detective = @clazz.new(@queue)
    
    @info = ['Amar Ben Belgacem', 'M', '392473902', '391225974', 'SD5', '+226', Time.parse('2010-02-10T22:17:39Z'), "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]" ]

    @info2 = [
      "Islam in the Democratic Republic of the Congo",
      "", 410276420, 395536324, "Anna Frodesiak", 12,
      "link ivory trade",
      "&lt;tr&gt;\n  &lt;td colspan=\"2\" class=\"diff-lineno\"&gt;Line 1:&lt;/td&gt;\n  &lt;td colspan=\"2\" class=\"diff-lineno\"&gt;Line 1:&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;{{islam by country}}&lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;{{islam by country}}&lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt;-&lt;/td&gt;\n  &lt;td class=\"diff-deletedline\"&gt;&lt;div&gt;\n'''[[Islam]] in the [[Democratic Republic of the Congo]]''' is not a recent phenomenon, as it has been present within the area since the 18th century, when [[Arab]] traders from [[East Africa]] pushed into the interior for [[ivory]] and [[slave]] trading purposes. Today, Muslims constitute approximately 10.4% of the Congolese population.&amp;lt;ref&amp;gt;[https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html CIA - The World Factbook - Congo, Democratic Republic of the&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;&amp;lt;ref&amp;gt;[http://www.state.gov/r/pa/ei/bgn/2823.htm Congo (Kinshasa) (01/08)&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;\n  &lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt;+&lt;/td&gt;\n  &lt;td class=\"diff-addedline\"&gt;&lt;div&gt;\n'''[[Islam]] in the [[Democratic Republic of the Congo]]''' is not a recent phenomenon, as it has been present within the area since the 18th century, when [[Arab]] traders from [[East Africa]] pushed into the interior for [[&lt;span class=\"diffchange\"&gt;ivory trade|&lt;/span&gt;ivory]] and [[slave]] trading purposes. Today, Muslims constitute approximately 10.4% of the Congolese population.&amp;lt;ref&amp;gt;[https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html CIA - The World Factbook - Congo, Democratic Republic of the&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;&amp;lt;ref&amp;gt;[http://www.state.gov/r/pa/ei/bgn/2823.htm Congo (Kinshasa) (01/08)&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;\n  &lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;==Notes==&lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;==Notes==&lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n",
      {"user"=>"Anna Frodesiak", "timestamp"=>"2011-01-27T00:47:31Z", "revid"=>"410276420", "size"=>"885", "title"=>"Islam in the Democratic Republic of the Congo", "from"=>"395536324", "parsedcomment"=>"link ivory trade", "to"=>"410276420", "parentid"=>"395536324", "ns"=>"0", "space"=>"preserve", "comment"=>"link ivory trade", "pageid"=>"6110090"},
      [],
      [
        ["https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html", "CIA - The World Factbook - Congo, Democratic Republic of the<!-- Bot generated title -->"]
      ]]
  end
  
  def test_find_revision_info
    #the url should be:
    #http://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=392473902&rvprop=ids|tags|flagged|timestamp|user|comment|size|flags|content
    revinfo = @detective.find_revision_info(@info2)
    assert_equal([], revinfo)
  end

#  def test_minor_info
#    revinfo = @detective.find_revision_info(@info2)
#    assert_equal([0], [revinfo[5]])
#  end
#
#  def test_link_info_links_added
#    revinfo = @detective.find_revision_info(@info2)
#    assert_equal([10], [revinfo[6]])
#  end
#
#  def test_link_info_no_links_added
#    revinfo = @detective.find_revision_info(@info)
#    assert_equal([0], [revinfo[6]])
#  end

  def test_link_info_new_page
    assert_nothing_raised do
      revinfo = @detective.find_revision_info([
        'Category talk:Presidents of the Chamber of Deputies of Chile',
        'N',
        '404102956',
        '415922166',
        'Koavf',
        '+21',
        Time.parse('2010-02-10T22:17:39Z'),
        "tag using [[Project:AWB|AWB]]"
      ])
    end
  end

  def test_investigate
    @clazz.setup_table(@db)
    rownum = @detective.investigate(@info)
    assert_equal(1.to_s, rownum.to_s)
  end
  
  def test_setup_table
    #to test the sql of the table definition
    assert_nothing_raised do
      @clazz.setup_table(@db)
    end
  end
  
end