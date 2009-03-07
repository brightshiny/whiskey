require "test/unit"
class Gobbler::GItemTest < ActiveSupport::TestCase
  
  test "extract_text" do
    # basic html
    html = '<a href="http://feeds2.feedburner.com/~ff/jkOnTheRun?a=pHjOPx4reOg:Vj&a=1&UUq&Qk;28JI:D7DqB2pKExk">a</a>'
    text = 'a'
    assert text == Gobbler::GItem.extract_text(html)

    # stray & test
    html = '<li>Palm and Sprint are co-hosting <a href="">an invite-only webcast</a> Q&A expected to follow.'
    text = 'Palm and Sprint are co-hosting an invite-only webcast Q&A expected to follow.'
    assert text == Gobbler::GItem.extract_text(html)

    # pre test
    html = '<pre>!_)#@($_#$)*@_!+@_!@&&_#!@$</pre>'
    text = '!_)#@($_#$)*@_!+@_!@&&_#!@$'
    assert text == Gobbler::GItem.extract_text(html)
    
    # &amp; test
    html = 'AT&amp;T'
    text = 'AT&T'
    assert text == Gobbler::GItem.extract_text(html)
    
    # stupid tracking collapses into a few spaces
    html = '<img alt="" border="0" src="http://stats.wordpress.com/b.gif?host=jkontherun.com&blog=4479943&post=31314&subd=jkontherun&ref=&feed=1" /><div class="feedflare"><a href="http://feeds2.feedburner.com/~ff/jkOnTheRun?a=GV4H5HVO21Y:b4tblmt0n_E:D7DqB2pKExk"><img src="http://feeds2.feedburner.com/~ff/jkOnTheRun?i=GV4H5HVO21Y:b4tblmt0n_E:D7DqB2pKExk" border="0"></img></a> <a href="http://feeds2.feedburner.com/~ff/jkOnTheRun?a=GV4H5HVO21Y:b4tblmt0n_E:V_sGLiPBpWU"><img src="http://feeds2.feedburner.com/~ff/jkOnTheRun?i=GV4H5HVO21Y:b4tblmt0n_E:V_sGLiPBpWU" border="0"></img></a> <a href="http://feeds2.feedburner.com/~ff/jkOnTheRun?a=GV4H5HVO21Y:b4tblmt0n_E:dnMXMwOfBR0"><img src="http://feeds2.feedburner.com/~ff/jkOnTheRun?d=dnMXMwOfBR0" border="0"></img></a> <a href="http://feeds2.feedburner.com/~ff/jkOnTheRun?a=GV4H5HVO21Y:b4tblmt0n_E:yIl2AUoC8zA"><img src="http://feeds2.feedburner.com/~ff/jkOnTheRun?d=yIl2AUoC8zA" border="0"></img></a> <a href="http://feeds2.feedburner.com/~ff/jkOnTheRun?a=GV4H5HVO21Y:b4tblmt0n_E:F7zBnMyn0Lo"><img src="http://feeds2.feedburner.com/~ff/jkOnTheRun?i=GV4H5HVO21Y:b4tblmt0n_E:F7zBnMyn0Lo" border="0"></img></a>'
    text = '    '
    assert text == Gobbler::GItem.extract_text(html)
  end
end