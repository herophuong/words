#!/usr/bin/env ruby
# encoding: utf-8
#
# PRODUCE A NEW SPHINX PROJECT DIRECTORY FOR TONE RECOGNITION
#
# Usage: From root directory, run: ./scripts/words2trvn.rb
#
require 'fileutils'

# Deprecated as "công" will collide with "coong", leave this here as a reference
unicode_to_telex_mapping = {
               "á" => "as",  "à" => "af",  "ả" => "ar",  "ã" => "ax",  "ạ" => "aj",
  "ă" => "aw", "ắ" => "aws", "ằ" => "awf", "ẳ" => "awr", "ẵ" => "awx", "ặ" => "awj",
  "â" => "aa", "ấ" => "aas", "ầ" => "aaf", "ẩ" => "aar", "ẫ" => "aax", "ậ" => "aaj",
               "é" => "es",  "è" => "ef",  "ẻ" => "er",  "ẽ" => "ex",  "ẹ" => "ej",
  "ê" => "ee", "ế" => "ees", "ề" => "eef", "ể" => "eer", "ễ" => "eex", "ệ" => "eej",
               "í" => "is",  "ì" => "if",  "ỉ" => "ir",  "ĩ" => "ix",  "ị" => "ij",
               "ó" => "os",  "ò" => "of",  "ỏ" => "or",  "õ" => "ox",  "ọ" => "oj",
  "ô" => "oo", "ố" => "oos", "ồ" => "oof", "ổ" => "oor", "ỗ" => "oox", "ộ" => "ooj",
  "ơ" => "ow", "ớ" => "ows", "ờ" => "owf", "ở" => "owr", "ỡ" => "owx", "ợ" => "owj",
               "ú" => "us",  "ù" => "uf",  "ủ" => "ur",  "ũ" => "ux",  "ụ" => "uj",
  "ư" => "uw", "ứ" => "uws", "ừ" => "uwf", "ử" => "uwr", "ữ" => "uwx", "ự" => "uwj",
               "ý" => "ys",  "ỳ" => "yf",  "ỷ" => "yr",  "ỹ" => "yx",  "ỵ" => "yj",
  "đ" => "dd"
}
unicode_to_vni_mapping = {
               "á" => "a1",  "à" => "a2",  "ả" => "a3",  "ã" => "a4",  "ạ" => "a5",
  "ă" => "a8", "ắ" => "a81", "ằ" => "a82", "ẳ" => "a83", "ẵ" => "a84", "ặ" => "a85",
  "â" => "a6", "ấ" => "a61", "ầ" => "a62", "ẩ" => "a63", "ẫ" => "a64", "ậ" => "a65",
               "é" => "e1",  "è" => "e2",  "ẻ" => "e3",  "ẽ" => "e4",  "ẹ" => "e5",
  "ê" => "e6", "ế" => "e61", "ề" => "e62", "ể" => "e63", "ễ" => "e64", "ệ" => "e65",
               "í" => "i1",  "ì" => "i2",  "ỉ" => "i3",  "ĩ" => "i4",  "ị" => "i5",
               "ó" => "o1",  "ò" => "o2",  "ỏ" => "o3",  "õ" => "o4",  "ọ" => "o5",
  "ô" => "o6", "ố" => "o61", "ồ" => "o62", "ổ" => "o63", "ỗ" => "o64", "ộ" => "o65",
  "ơ" => "o7", "ớ" => "o71", "ờ" => "o72", "ở" => "o73", "ỡ" => "o74", "ợ" => "o75",
               "ú" => "u1",  "ù" => "u2",  "ủ" => "u3",  "ũ" => "u4",  "ụ" => "u5",
  "ư" => "u7", "ứ" => "u71", "ừ" => "u72", "ử" => "u73", "ữ" => "u74", "ự" => "u75",
               "ý" => "y1",  "ỳ" => "y2",  "ỷ" => "y3",  "ỹ" => "y4",  "ỵ" => "y5",
  "đ" => "d9"  
}

train_fileids = []
train_transcription = []
test_fileids = []
test_transcription = []
diacritic_stats = {"unmarked" => 0, "acute" => 0, "grave" => 0, "hook" => 0, "tilde" => 0, "dot" => 0}
Dir.glob("wav/*").each_with_index do |user_dir, index|
  %w[unmarked acute grave hook tilde dot].each do |diacritic|
    words = Dir.glob(user_dir + "/#{diacritic}/*")
    total =  words.count
    diacritic_stats[diacritic] = total
    test_count = total / 5

    # Convert unicode name to ascii name using vni sequences
    dest_words = words.map do |word|
      dest_word = String.new word
      unicode_to_vni_mapping.each do |k, v|
        loop do
          dest_word[k] &&= v
          break if dest_word[k].nil?
        end
      end
      dest_word = File.join("trvn", dest_word)
      dest_word.sub!("#{diacritic}/", "#{index}_")
      dest_word
    end

    dest_dir = File.join("trvn", user_dir)
    if !Dir.exists?(dest_dir)
      FileUtils.mkdir_p(dest_dir)
    end

    words.each_with_index do |word, word_idx|
      print "\rCopy #{user_dir}/#{diacritic} #{(word_idx + 1) * 100 / total}%"
      if File.exists?(dest_words[word_idx])
          throw Exception.new("duplicated file #{dest_words[word_idx]}")
      end
      FileUtils.cp(word, dest_words[word_idx])
    end
    print "\n"

    # Add words to train and test database
    test_words = dest_words.sample(test_count)
    train_words = dest_words.reject{|w| test_words.include? w}
    test_words.each do |word|
      test_fileids << word.sub("trvn/wav/", "").sub(".wav", "")
      test_transcription << "<s> #{diacritic.upcase} </s> (#{File.basename(word).sub(".wav", "")})"
    end
    train_words.each do |word|
      train_fileids << word.sub("trvn/wav/", "").sub(".wav", "")
      train_transcription << "<s> #{diacritic.upcase} </s> (#{File.basename(word).sub(".wav", "")})"
    end
  end
end

# Save database to files
if !Dir.exists?("trvn/etc")
  Dir.mkdir("trvn/etc")
end
File.write("trvn/etc/trvn_train.fileids", train_fileids.join("\n") + "\n")
File.write("trvn/etc/trvn_train.transcription", train_transcription.join("\n") + "\n")
File.write("trvn/etc/trvn_test.fileids", test_fileids.join("\n") + "\n")
File.write("trvn/etc/trvn_test.transcription", test_transcription.join("\n") + "\n")

blacklist = File.open("words-blacklist.txt").read.split("\n")
words = File.open("words.txt").read.split("\n").reject{|w| blacklist.include? w }
File.write("diacritics.tmp.txt", words.map{ |word|
  case word
  when /[áắấéếíóốớúứý]/
    '<s> ACUTE </s>'
  when /[àằầèềìòồờùừỳ]/
    '<s> GRAVE </s>'
  when /[ảẳẩẻểỉỏổởủửỷ]/
    '<s> HOOK </s>'
  when /[ãẵẫẽễĩõỗỡũữỹ]/
    '<s> TILDE </s>'
  when /[ạặậẹệịọộợụựỵ]/
    '<s> DOT </s>'
  else
    '<s> UNMARKED </s>'
  end
}.join("\n"))
system("text2wfreq < diacritics.tmp.txt | wfreq2vocab > diacritics.tmp.vocab")
system("text2idngram -vocab diacritics.tmp.vocab -idngram diacritics.tmp.idngram < diacritics.tmp.txt")
system("idngram2lm -vocab_type 0 -idngram diacritics.tmp.idngram -vocab diacritics.tmp.vocab -arpa diacritics.tmp.arpa")
system("sphinx_lm_convert -i diacritics.tmp.arpa -o trvn/etc/trvn.lm.DMP")
system("rm *.tmp.*")

puts "Creating trvn.dic..."
File.write "trvn/etc/trvn.dic", <<DIC
UNMARKED UNMARKED_START UNMARKED_MID UNMARKED_END
ACUTE ACUTE_START ACUTE_MID ACUTE_END
GRAVE GRAVE_START GRAVE_MID GRAVE_END
HOOK HOOK_START HOOK_MID HOOK_END
TILDE TILDE_START TILDE_MID TILDE_END
DOT DOT_START DOT_MID DOT_END
DIC

puts "Creating trvn.filler..."
File.write "trvn/etc/trvn.filler", <<FILLER
<s> SIL
</s> SIL
<sil> SIL
FILLER

puts "Creating trvn.phone..."
File.write "trvn/etc/trvn.phone", <<PHONE
SIL
UNMARKED_START
UNMARKED_MID
UNMARKED_END
ACUTE_START
ACUTE_MID
ACUTE_END
GRAVE_START
GRAVE_MID
GRAVE_END
HOOK_START
HOOK_MID
HOOK_END
TILDE_START
TILDE_MID
TILDE_END
DOT_START
DOT_MID
DOT_END
PHONE

puts "Creating trvn.fsg..."
File.write "trvn/etc/trvn.jsgf", <<JSGF
#JSGF V1.0;
/**
 * JSGF Grammar for Hello World example
 */
grammar diacritics;
public <diacritic> = (UNMARKED | ACUTE | GRAVE | HOOK | TILDE | DOT);
JSGF
system("sphinx_jsgf2fsg -jsgf trvn/etc/trvn.jsgf -fsg trvn/etc/trvn.fsg")
