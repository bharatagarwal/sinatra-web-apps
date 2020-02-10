require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

before do
  @contents = File.readlines('data/toc.txt', chomp: true)
end

helpers do
  def in_paragraphs(string)
    string.split("\n\n").each_with_index.map do |line, index|
      "<p id=paragraph#{index}>#{line}</p>"
    end.join
  end

  def highlight(text, match)
    text.gsub(match, "<strong>#{match}</strong>")
  end
end

not_found do
  redirect '/'
end

get '/' do
  @title = 'The Adventures of Sherlock Holmes'
  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect '/' unless (1..@contents.size).cover?(number)

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

def chapters_matching(query)
  results = []
  return results if (query == nil || query.empty?)

  @contents.each_with_index do |chapter_name, index|
    matches = {}
    chapter_number = index + 1
    chapter_content = File.read("data/chp#{chapter_number}.txt")

    chapter_content.split("\n\n").each_with_index do |paragraph, p_idx|
      matches[p_idx] = paragraph if paragraph.include?(query)
    end

    if matches.any?
      results << {number: chapter_number, name: chapter_name, paragraphs: matches}
    end
  end

  results
end

get '/search' do
  @results = chapters_matching(params[:query])
  erb :search
end
