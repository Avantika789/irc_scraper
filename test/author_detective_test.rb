require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'author_detective.rb'

require 'time'

class AuthorDetectiveTest < Test::Unit::TestCase
  def setup
    @db = SQLite3::Database.new(":memory:")
    @db.execute('CREATE TABLE irc_wikimedia_org_en_wikipedia ( id integer primary key autoincrement,
      article_name varchar(128) not null,
      desc varchar(8),
      revision_id integer,
      old_id integer,
      user varchar(64),
      byte_diff integer,
      ts timestamp(20),
      description text)')
    @clazz = AuthorDetective
    @queue = []
    @detective = @clazz.new(@queue)
    @info = [
      "Islam in the Democratic Republic of the Congo",
      "", 410276420, 395536324, "Anna Frodesiak", 12,
      "link ivory trade",
      "&lt;tr&gt;\n  &lt;td colspan=\"2\" class=\"diff-lineno\"&gt;Line 1:&lt;/td&gt;\n  &lt;td colspan=\"2\" class=\"diff-lineno\"&gt;Line 1:&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;{{islam by country}}&lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;{{islam by country}}&lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt;-&lt;/td&gt;\n  &lt;td class=\"diff-deletedline\"&gt;&lt;div&gt;\n'''[[Islam]] in the [[Democratic Republic of the Congo]]''' is not a recent phenomenon, as it has been present within the area since the 18th century, when [[Arab]] traders from [[East Africa]] pushed into the interior for [[ivory]] and [[slave]] trading purposes. Today, Muslims constitute approximately 10.4% of the Congolese population.&amp;lt;ref&amp;gt;[https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html CIA - The World Factbook - Congo, Democratic Republic of the&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;&amp;lt;ref&amp;gt;[http://www.state.gov/r/pa/ei/bgn/2823.htm Congo (Kinshasa) (01/08)&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;\n  &lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt;+&lt;/td&gt;\n  &lt;td class=\"diff-addedline\"&gt;&lt;div&gt;\n'''[[Islam]] in the [[Democratic Republic of the Congo]]''' is not a recent phenomenon, as it has been present within the area since the 18th century, when [[Arab]] traders from [[East Africa]] pushed into the interior for [[&lt;span class=\"diffchange\"&gt;ivory trade|&lt;/span&gt;ivory]] and [[slave]] trading purposes. Today, Muslims constitute approximately 10.4% of the Congolese population.&amp;lt;ref&amp;gt;[https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html CIA - The World Factbook - Congo, Democratic Republic of the&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;&amp;lt;ref&amp;gt;[http://www.state.gov/r/pa/ei/bgn/2823.htm Congo (Kinshasa) (01/08)&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;\n  &lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;==Notes==&lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;==Notes==&lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n",
      {"user"=>"Anna Frodesiak", "timestamp"=>"2011-01-27T00:47:31Z", "revid"=>"410276420", "size"=>"885", "title"=>"Islam in the Democratic Republic of the Congo", "from"=>"395536324", "parsedcomment"=>"link ivory trade", "to"=>"410276420", "parentid"=>"395536324", "ns"=>"0", "space"=>"preserve", "comment"=>"link ivory trade", "pageid"=>"6110090"},
      [],
      [
        ["https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html", "CIA - The World Factbook - Congo, Democratic Republic of the<!-- Bot generated title -->"]
      ]
    ]

    @info2 = [
      "Islam in the Democratic Republic of the Congo",
      "", 392473902, 391225974, "Alice", 12,
      "link ivory trade",
      "&lt;tr&gt;\n  &lt;td colspan=\"2\" class=\"diff-lineno\"&gt;Line 1:&lt;/td&gt;\n  &lt;td colspan=\"2\" class=\"diff-lineno\"&gt;Line 1:&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;{{islam by country}}&lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;{{islam by country}}&lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt;-&lt;/td&gt;\n  &lt;td class=\"diff-deletedline\"&gt;&lt;div&gt;\n'''[[Islam]] in the [[Democratic Republic of the Congo]]''' is not a recent phenomenon, as it has been present within the area since the 18th century, when [[Arab]] traders from [[East Africa]] pushed into the interior for [[ivory]] and [[slave]] trading purposes. Today, Muslims constitute approximately 10.4% of the Congolese population.&amp;lt;ref&amp;gt;[https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html CIA - The World Factbook - Congo, Democratic Republic of the&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;&amp;lt;ref&amp;gt;[http://www.state.gov/r/pa/ei/bgn/2823.htm Congo (Kinshasa) (01/08)&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;\n  &lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt;+&lt;/td&gt;\n  &lt;td class=\"diff-addedline\"&gt;&lt;div&gt;\n'''[[Islam]] in the [[Democratic Republic of the Congo]]''' is not a recent phenomenon, as it has been present within the area since the 18th century, when [[Arab]] traders from [[East Africa]] pushed into the interior for [[&lt;span class=\"diffchange\"&gt;ivory trade|&lt;/span&gt;ivory]] and [[slave]] trading purposes. Today, Muslims constitute approximately 10.4% of the Congolese population.&amp;lt;ref&amp;gt;[https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html CIA - The World Factbook - Congo, Democratic Republic of the&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;&amp;lt;ref&amp;gt;[http://www.state.gov/r/pa/ei/bgn/2823.htm Congo (Kinshasa) (01/08)&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;\n  &lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;==Notes==&lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;==Notes==&lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n",
      {"user"=>"Alice", "timestamp"=>"2011-01-27T00:47:31Z", "revid"=>"410276420", "size"=>"885", "title"=>"Islam in the Democratic Republic of the Congo", "from"=>"395536324", "parsedcomment"=>"link ivory trade", "to"=>"410276420", "parentid"=>"395536324", "ns"=>"0", "space"=>"preserve", "comment"=>"link ivory trade", "pageid"=>"6110090"},
      [],
      [
        ["https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html", "CIA - The World Factbook - Congo, Democratic Republic of the<!-- Bot generated title -->"]
      ]
    ]
  end
  
  def test_find_account_history_create_life_groups_block
    account_history = @detective.find_account_history(@info)
    assert_equal([1226854535, 69234716, 17712, "BAhbCCIRYXV0b3Jldmlld2VyIg1yZXZpZXdlciIPcm9sbGJhY2tlcg==\n", 0,], 
      account_history[0..2]+account_history[10..11])

  end
  
  def test_find_account_edit_bucket
    #so all of these values are going to change (upward only in theory...we'll test against known values)
    #all these values should change (as time goes on, they're all time dependent!)
    account_history = @detective.find_account_history(@info)
    assert_operator 10, :<=, account_history[2], "total edit count"
    assert_operator 0, :<=, account_history[3], "second ago"
    assert_operator 0, :<=, account_history[4], "minute"
    assert_operator 0, :<=, account_history[5], "hour"
    assert_operator 0, :<=, account_history[6], "day"
    assert_operator 0, :<=, account_history[7], "week"
    assert_operator 0, :<=, account_history[8], "month"
    assert_operator 10, :<=, account_history[9], "year"
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

  def test_block_info
    account_history =  @detective.find_account_history(@info2)
    assert_equal([1,764932, "Picaroon", nil, "[[Wikipedia:Requests for checkuser/Case/W. Frank|sockpuppet of W. Frank]]"],
       [account_history[11], account_history[12], account_history[13], account_history[15], account_history[16]])
  end

  def test_non_existent_author_info
    res = @detective.find_account_history([
      'Saoula',
      'hello',
      '403706560',
      '403544118',
      '41.105.23.56',
      '+33',
      Time.parse('2010-02-10T22:17:39Z'),
      ""
    ])
    assert_equal(['-', 0, 1, 0, 0, 0, 0, 0, 0, 1, "", 0, ""], res)
  end
end