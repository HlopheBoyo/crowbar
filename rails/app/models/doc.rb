# Copyright 2014, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governnig permissions and
# limitations under the License.
#

class Doc < ActiveRecord::Base

  NEWREADME = 'README.md.new'

  belongs_to :barclamp
  belongs_to :parent, :class_name => "Doc"
  has_many :children, :class_name => "Doc", :foreign_key => "parent_id"

  validates_uniqueness_of :name, :scope=>:barclamp_id, :on => :create, :case_sensitive => false, :message => I18n.t("db.notunique", :default=>"Doc handle must be unique")

  scope :roots, where(:parent_id=>nil)
  scope :roots_by_barclamp, lambda { |barclamp_id| where(:parent_id=>nil, :barclamp_id=>barclamp_id) }

  def <=>(b)
    x = order <=> b.order if order and b.order
    x = name <=> b.name if x == 0
    return x
  end

  def self.root_directory
    File.join('../doc')
  end


  # creates the table of contents from the files
  def self.gen_doc_index
    # determine age of doc index file in seconds (so we don't generate every time we start)
    index_age =  File.new(File.join '..', 'doc', NEWREADME).mtime - DateTime.now rescue 0
    if Doc.count == 0 or index_age < -300
      # load barclamp docs
      Barclamp.order(:id).each { |bc| Doc.discover_docs bc if bc.parent.id == bc.id }
      Doc.make_index NEWREADME if Rails.env.eql? 'development'
    end
    Doc.all
  end

  # Generate a top level README containing the docs index
  # in markdown format, for github karma 
  def self.make_index name
    index = File.open File.join(Rails.root, '..', 'doc', name), 'w'
    index << "_Autogenerated, do not edit!_\n"
    index << "\n\n# [Project Welcome Page](../README.md)\n\n"
    index << "\n# OpenCrowbar Table of Contents\n"
    Doc.roots.sort.each do |doc_entry|
      index << "\n  1. [#{doc_entry.description}](#{File.join('.', doc_entry.name)})"
    end
    index << "\n\n\n# Documentation Full Index\n"
    Doc.roots.sort.each do |d|
       make_index_entries index, d
    end
    index.close
  end

  # Generate individual index entries for the markdown format
  # docs index
  def self.make_index_entries(index, doc_entry)
    index << "\n#{"  "*doc_entry.level}1. [#{doc_entry.description}](#{File.join('.', doc_entry.name)})"
    if doc_entry.level < 3
      doc_entry.children.sort.each do |c| 
        make_index_entries index, c
      end
    end
  end

  def self.topic_expand(name, html=true)
    text = "\n"
    topic = Doc.find_by_name name
    if topic.children.size > 0
      topic.children.each do |t|
        file = page_path root_directory, t.name
        if File.exist? file
          raw = IO.read(file)
          text += (html ? BlueCloth.new(raw).to_html : raw)
          text += topic_expand(t.name, html)
        end
      end
    end
    return text
  end

  # scan the directories and find files
  def self.discover_docs barclamp

    doc_path = File.join barclamp.source_path, 'doc'
    Rails.logger.debug("Discovering docs for #{barclamp.name} barclamp under #{doc_path}") 

    files_list = %x[find #{doc_path} -name README.md]
    files = files_list.split("\n").sort  # to ensure that parents come before their children
    files.each do |file_name|
      name = file_name.sub(doc_path, '')
      Doc.create_doc name, barclamp
    end

    files_list = %x[find #{doc_path} -name *.md]
    files = files_list.split("\n").sort  # to ensure that parents come before their children
    files.each do |file_name|
      name = file_name.sub(doc_path, '')
      Doc.create_doc name, barclamp
    end

  end

  def level 
    name.count("/")-1
  end

  def index?
    name.downcase.ends_with? "readme.md"
  end

  def exist?
    File.exist? file_name
  end

  def file_name
    File.join doc_path, name
  end

  def doc_path
    File.join barclamp.source_path, 'doc'
  end

  def self.create_doc name, barclamp
    d = Doc.where(:name=>name).first
    unless d
      d = Doc.new :name=>name, :barclamp=>barclamp
      return nil unless d.exist?
      d.parent = d.generate_parent name
      d.barclamp = barclamp || d.parent.barclamp
      d.description = d.find_title
      return nil unless d.description
      d.order = d.find_order
      d.save!
    end
    d
  end
   
  def generate_parent pass_name=nil
    p = find_parent_name pass_name || name
    Doc.where(:name=>p).first || Doc.create_doc(p, barclamp)
  end

  def find_parent_name file_name=nil
    dpath = doc_path
    parent_dir = File.dirname file_name || name
    if index?
      f = File.join dpath, parent_dir, "..", "README.md"
      fabs = File.absolute_path f, dpath
      fabs.sub(dpath, '')
    else
      File.join parent_dir, "README.md"
    end
  end

  def find_title
    # figure out title, the first markdown header in the file
    begin
      actual_title = File.open(file_name, 'r').readline
      # we require titles to start w/ # - anything else is considered extra content
      return actual_title.strip[/^#+(.*?)#*$/,1].strip.truncate(120) if actual_title.starts_with? "#"
    rescue
      nil
    end
    nil
  end

  def find_order
    o = name[/\/([0-9]+)_[^\/]*$/,1] || "9999"
    o.to_s.rjust(6,'0') rescue "!error"
  end

  def git_url
    path = self.name.split '/'
    path[0] = "#{self.barclamp.source_url}/tree/master/doc"
    return path.join('/')
  end

end
