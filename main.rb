# coding: utf-8
require 'json'
require 'rss'
require 'open-uri'
require 'natto'
require 'gruff'
require 'mechanize'
require 'sequel'

def get_hatebu(target_url)
  sleep(3)
  url = 'http://b.hatena.ne.jp/entry/jsonlite/?url=' + target_url
  json = ''
  open(url) do |f|
    json = JSON.parse(f.read)
  end
  json
end

def get_title(url)
  agent = Mechanize.new
  page = agent.get(url)
  page.title
end

# 記事urlを受け取る 
def graph_aggregation_of_words_in_blog(url, pattern = /名詞/, num = 10)
  result_dir_path = './graphs/ranking'
  Dir.mkdir(result_dir_path) unless Dir.exist?(result_dir_path)

  title = get_title(url).gsub(/\s|\||\//,'')
  title = title == "" ? "notitle" : title
  surfaces = []
  json = get_hatebu(url)
  json['bookmarks'].each do |bm|
    nm = Natto::MeCab.new
    nm.parse(bm['comment']) do |n|
      surfaces.push n.surface if n.feature.match(pattern) &&
                                 n.surface.length > 2
    end
  end
  surface_map = get_surface_map(surfaces)
  header = {}
  surface_map.each_with_index { |v, i| header[i] = v[:name] }
  data_maps = [{ key: :surfaces,
                 data: surface_map.map { |v| v[:count] }.take(num) }]
  write_graph(header.take(num).to_h, data_maps, title , result_dir_path)
end

def get_rss_blog_surfaces(url, pattern = /名詞/, min_length = 2)
  surfaces = []
  RSS::Parser.parse(url).items.map(&:link).each do |x|
    json = get_hatebu(x)
    json['bookmarks'].each do |bm|
      nm = Natto::MeCab.new
      nm.parse(bm['comment']) do |n|
        surfaces.push n.surface if n.feature.match(pattern) && n.surface.length > min_length
      end
    end
  end
  surfaces
end

def get_surface_map(surfaces)
  surface_map = surfaces.uniq.map do |s_i|
    { count: surfaces.filter { |s_j| s_j == s_i }.count, name: s_i }
  end
  surface_map.sort_by { |v| v[:count] }.reverse
end

def create_hatebu_words_graph(num = 10)
  result_dir_path = 'graphs/hatebu_all'
  Dir.mkdir(result_dir_path) unless Dir.exist?(result_dir_path)
  surface_map = get_surface_map(get_rss_blog_surfaces('http://b.hatena.ne.jp/hotentry/it.rss'))
  header = {}
  surface_map.each_with_index { |v, i| header[i] = v[:name] }
  data_maps = [{ key: :surfaces,
                 data: surface_map.map { |v| v[:count] }.take(num) }]
  write_graph(header.take(num).to_h, data_maps, 'result', result_dir_path)
end

def write_graph(labels, data_maps, title, result_dir_path)
  g = Gruff::Line.new
  g.marker_font_size = 10
  g.title = title
  # Because it is not displayed in case of Japanese, it is need
  g.font = './hiragino_w0.ttc'
  g.labels = labels
  data_maps.each do |data_map|
    g.data data_map[:key], data_map[:data]
  end
  p title
  g.write("#{result_dir_path}/#{title}.png")
end

Dir.mkdir('graphs') unless Dir.exist?('graphs')
# create_hatebu_words_graph

# graph_aggregation_of_words_in_blog(url= 'https://www.gizmodo.jp/2019/02/i-cut-the-big-five-tech-giants-from-my-life-it-was-hell.html', match = /名詞/ ,num=15)
# url = 'http://b.hatena.ne.jp/hotentry/it.rss'
# RSS::Parser.parse(url).items.map(&:link).map do |x|
#   graph_aggregation_of_words_in_blog(url = x, match = /名詞/ ,num = 15)
# end

