# coding: utf-8
require 'sequel'
DB = Sequel.connect('sqlite://./hatena.db')
DB.create_table!(:bookmarks) do
  primary_key :id
  String :tags_string           # 空白で結合する。
  String :comment
  String :user
  String :timestamp
end

DB.create_table!(:hatebus) do
  primary_key :eid
  foreign_key :bookmark_id, :bookmarks
  String :screenshot
  String :entry_url
  String :title
  String :url
  Integer :count
end
