require "test/unit"

require_relative '../modules/sentence.rb'

class SeverTest < Test::Unit::TestCase
  def test_unicode
    s = "David Cameron: Taxes will rise unless we can raid bank accounts ( ﾟ∀ﾟ)ｱﾊﾊ八八ﾉヽﾉヽﾉヽﾉ ＼"
    e = %w(David Cameron : Taxes will rise unless we can raid bank accounts ( ﾟ ∀ ﾟ ) ｱﾊﾊ八八ﾉヽﾉヽﾉヽﾉ ＼)

    self.assert_sentence s, e
  end

  def test_latex
    s = "4Artist: 12 m3n Soundtrack 3:: YouTube Shinedown - I'm advancing... Doing (g^{y_i})^{x_i} I don't actually know who sits in front of draenor."
    e = %w(4Artist : 12 m3n Soundtrack 3 :: YouTube Shinedown - I ' m advancing ... Doing ( g ^{ y _ i })^{ x _ i } I don ' t actually know who sits in front of draenor .)
    
    self.assert_sentence s, e
  end

  def test_youtube_url
    s = "http://youtu.be/55byw2NSuPI A Skylit Drive - Love the Way You Lie - 00:04:58 - 236723 views"
    e = %w(http://youtu.be/55byw2NSuPI A Skylit Drive - Love the Way You Lie - 00 : 04 : 58 - 236723 views)

    self.assert_sentence s, e
  end

  def test_temperature
    s = "huh I'd still want you to be taught and read up on Eight Floppy Drives | Lo: 53.53°F"
    e = %w(huh I ' d still want you to be taught and read up on Eight Floppy Drives | Lo : 53 . 53 ° F)

    self.assert_sentence s, e
  end

  def test_long_dashed_url
    s = "taken from : http://highscalability.com/blog/2014/6/23/performance-at-scale-ssds-silver-bullets-and-serialization.html"
    e = %w(taken from : http://highscalability.com/blog/2014/6/23/performance-at-scale-ssds-silver-bullets-and-serialization.html)

    self.assert_sentence s, e
  end

  def test_symbols_url
    s = "http://www.computerworld.com/article/2474991/it-careers/women-computer-science-grads--the-bump-before-the-decline.html -> Women computer science grads: The bump before the decline ..."
    e = %w(http://www.computerworld.com/article/2474991/it-careers/women-computer-science-grads--the-bump-before-the-decline.html -> Women computer science grads : The bump before the decline ...)

    self.assert_sentence s, e
  end

  def test_spanish_accented
    s = "¿Por qué se rompió el avión?"
    e = %w(¿ Por qué se rompió el avión ?)

    self.assert_sentence s, e
  end

  def test_french_accented
    s = "Quel âge avez-vous?"
    e = %w(Quel âge avez - vous ?)

    self.assert_sentence s, e
  end

  def test_polish
    s = "Uczestnicy zagrali w czterech miastach: Lanciano, Vasto, Ortona oraz w Chieti gdzie odbył się odbył się mecz o trzecie miejsce razem z finałem."
    e = %w(Uczestnicy zagrali w czterech miastach : Lanciano , Vasto , Ortona oraz w Chieti gdzie odbył się odbył się mecz o trzecie miejsce razem z finałem .)

    self.assert_sentence s, e
  end

  def test_russian
    s = "А. А. Блок, А. Белый, В. И. Иванов. «Младшие» символисты воспринимали символизм в философско-религиозном плане."
    e = %w(А . А . Блок , А . Белый , В . И . Иванов . « Младшие » символисты воспринимали символизм в философско - религиозном плане .)

    self.assert_sentence s, e
  end

  def test_mandarin
    s = "以下是经过上述调整后的《第一批异体字整理表》，它由原来的810组异体字减少到796组，淘汰的异体字由原来的1053个减少到1027个。"
    e = %w(以 下 是 经 过 上 述 调 整 后 的 《 第 一 批 异 体 字 整 理 表 》 ， 它 由 原 来 的 810 组 异 体 字 减 少 到 796 组 ，淘 汰 的 异 体 字 由 原 来 的 1053 个 减 少 到 1027 个 。)

    #self.assert_sentence s, e
    #This requires some special severing... With my understanding of mandarin, each bit would need to be separate.
  end

  def test_code_rst
    s = "<%= render(:partial => 'display_block', :collection => report_block.display_blocks)%>"
    e = %w(<%= render (: partial => ' display _ block ', : collection => report _ block . display _ blocks )%>)

    self.assert_sentence s, e
  end

  def assert_sentence( base_sentence, array )
    # Run sentence in, through, and back out
    sentence = Sentence.new base_sentence  

    #print "\n\n"
    #print "Sentence in: ", base_sentence, "\n"
    #print "Sentence out: ", sentence.to_s, "\n\n"

    #print "Sentence parts: ", sentence.words.map{ |w| w.text }, "\n\n"

    # Check that the array's sizes are equal
    assert_equal array.size, sentence.size

    # Check that the two arrays are equal
    for i in array.size.times do
      assert_equal array[i], sentence[i].to_s
    end

    # Check that the output is equal to our input
    assert_equal base_sentence, sentence.to_s 
  end
end
