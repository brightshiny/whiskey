module StopWord
  
  def is_stop_word?(word)
      STOP_WORDS.has_key?(word)
  end
  module_function :is_stop_word?
  
  STOP_WORDS = {
    "0"=>true, "1"=>true, "2"=>true, "3"=>true, "4"=>true, "5"=>true,
    "6"=>true, "7"=>true, "8"=>true, "9"=>true, "000"=>true, "$"=>true,
    "about"=>true, "after"=>true, "all"=>true, "also"=>true, "an"=>true,
    "and"=>true, "another"=>true, "any"=>true, "are"=>true, "as"=>true,
    "at"=>true, "be"=>true, "because"=>true, "been"=>true, "before"=>true,
    "being"=>true, "between"=>true, "both"=>true, "but"=>true, "by"=>true,
    "came"=>true, "can"=>true, "come"=>true, "could"=>true, "did"=>true,
    "do"=>true, "does"=>true, "each"=>true, "else"=>true, "for"=>true,
    "from"=>true, "get"=>true, "got"=>true, "has"=>true, "had"=>true,
    "he"=>true, "have"=>true, "her"=>true, "here"=>true, "him"=>true,
    "himself"=>true, "his"=>true, "how"=>true,"if"=>true, "in"=>true,
    "into"=>true, "is"=>true, "it"=>true, "its"=>true, "just"=>true,
    "like"=>true, "make"=>true, "many"=>true, "me"=>true, "might"=>true,
    "more"=>true, "most"=>true, "much"=>true, "must"=>true, "my"=>true,
    "never"=>true, "now"=>true, "of"=>true, "on"=>true, "only"=>true,
    "or"=>true, "other"=>true, "our"=>true, "out"=>true, "over"=>true,
    "re"=>true, "said"=>true, "same"=>true, "see"=>true, "should"=>true,
    "since"=>true, "so"=>true, "some"=>true, "still"=>true, "such"=>true,
    "take"=>true, "than"=>true, "that"=>true, "the"=>true, "their"=>true,
    "them"=>true, "then"=>true, "there"=>true, "these"=>true,
    "they"=>true, "this"=>true, "those"=>true, "through"=>true,
    "to"=>true, "too"=>true, "under"=>true, "up"=>true, "use"=>true,
    "very"=>true, "want"=>true, "was"=>true, "way"=>true, "we"=>true,
    "well"=>true, "were"=>true, "what"=>true, "when"=>true, "where"=>true,
    "which"=>true, "while"=>true, "who"=>true, "will"=>true, "with"=>true,
    "would"=>true, "you"=>true, "your"=>true, "a"=>true, "b"=>true,
    "c"=>true, "d"=>true, "e"=>true, "f"=>true, "g"=>true, "h"=>true,
    "i"=>true, "j"=>true, "k"=>true, "l"=>true, "m"=>true, "n"=>true,
    "o"=>true, "p"=>true, "q"=>true, "r"=>true, "s"=>true, "t"=>true,
    "u"=>true, "v"=>true, "w"=>true, "x"=>true, "y"=>true, "z"=>true
  }
end
