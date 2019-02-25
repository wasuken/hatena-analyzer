# coding: utf-8
require 'json'
require 'rss'
require 'open-uri'
require 'natto'
require 'gruff'

def get_hatebu(target_url)
  sleep(3)
  url = 'http://b.hatena.ne.jp/entry/jsonlite/?url=' + target_url
  json = ''
  open(url) do |f|
    json = JSON.parse(f.read)
  end
  json
end

Dir.mkdir('graphs') if !Dir.exists?('graphs')

url = 'http://b.hatena.ne.jp/hotentry/it.rss'
rss = RSS::Parser.parse(url)
surfaces = []
rss.items.each do |x|
  json = get_hatebu(x.link)
  json['bookmarks'].each do |bm|
    nm = Natto::MeCab.new
    nm.parse(bm['comment']) do |n|
      surfaces.push n.surface if n.feature.match(/動詞|名詞/) && n.surface.length > 2
    end
  end
end

surface_map = surfaces.uniq.map{|s_i| {count: surfaces.filter{|s_j| s_j == s_i}.count,name: s_i}}
surface_map.sort_by!{|v| v[:count]}.reverse!
header = {}
surface_map.each_with_index{|v,i| header[i] = v[:name]}
g = Gruff::Line.new
g.marker_font_size = 10
g.title = '結果'
# お好みで
g.font = "./hiragino_w0.ttc"
g.labels = header.take(10).to_h
g.data :surfaces, surface_map.map{|v| v[:count]}.take(10)
g.write("./graphs/result.png")
