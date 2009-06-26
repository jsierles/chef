#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require 'chef/cookbook/metadata'

describe Chef::Cookbook::Metadata do 
  before(:each) do
    @cookbook = Chef::Cookbook.new('test_cookbook')
    @meta = Chef::Cookbook::Metadata.new(@cookbook)
  end

  describe "initialize" do
    it "should return a Chef::Cookbook::Metadata object" do
      @meta.should be_a_kind_of(Chef::Cookbook::Metadata)
    end
    
    it "should allow a cookbook as the first argument" do
      lambda { Chef::Cookbook::Metadata.new(@cookbook) }.should_not raise_error
    end

    it "should allow an maintainer name for the second argument" do
      lambda { Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown') }.should_not raise_error
    end

    it "should set the maintainer name from the second argument" do
      md = Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown') 
      md.maintainer.should == 'Bobo T. Clown'
    end

    it "should allow an maintainer email for the third argument" do
      lambda { Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown', 'bobo@clown.co') }.should_not raise_error
    end

    it "should set the maintainer email from the third argument" do
      md = Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown', 'bobo@clown.co') 
      md.maintainer_email.should == 'bobo@clown.co'
    end

    it "should allow a license for the fourth argument" do
      lambda { Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown', 'bobo@clown.co', 'Clown License v1') }.should_not raise_error
    end

    it "should set the license from the fourth argument" do
      md = Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown', 'bobo@clown.co', 'Clown License v1') 
      md.license.should == 'Clown License v1'
    end
  end 

  describe "cookbook" do
    it "should return the cookbook we were initialized with" do
      @meta.cookbook.should eql(@cookbook)
    end
  end

  describe "name" do
    it "should return the name of the cookbook" do
      @meta.name.should eql(@cookbook.name)
    end
  end

  describe "platforms" do
    it "should return the current platform hash" do
      @meta.platforms.should be_a_kind_of(Hash)  
    end
  end

  describe "adding a supported platform" do
    it "should support adding a supported platform with a single expression" do
      @meta.supports("ubuntu", ">= 8.04")
      @meta.platforms["ubuntu"].should == [ '>= 8.04' ]
    end

    it "should support adding a supported platform with multiple expressions" do
      @meta.supports("ubuntu", ">= 8.04", "= 9.04")
      @meta.platforms["ubuntu"].should == [ '>= 8.04', "= 9.04" ]
    end
  end

  describe "meta-data attributes" do
    params = {
      :maintainer => "Adam Jacob",
      :maintainer_email => "adam@opscode.com",
      :license => "Apache v2.0",
      :description => "Foobar!",
      :long_description => "Much Longer\nSeriously",
      :version => "0.6"
    }
    params.sort { |a,b| a.to_s <=> b.to_s }.each do |field, field_value|
      describe field do
        it "should be set-able via #{field}" do
          @meta.send(field, field_value).should eql(field_value)
        end
        it "should be get-able via #{field}" do
          @meta.send(field, field_value)
          @meta.send(field).should eql(field_value)
        end
      end
    end
  end

  describe "dependency specification" do
    dep_types = {
      :depends     => [ :dependencies, "foo::bar", ">> 0.2" ],
      :recommends  => [ :recommendations, "foo::bar", ">> 0.2" ],
      :suggests    => [ :suggestions, "foo::bar", ">> 0.2" ],
      :conflicts   => [ :conflicting, "foo::bar", ">> 0.2" ],
      :provides    => [ :providing, "foo::bar", ">> 0.2" ],
      :replaces    => [ :replacing, "foo::bar", ">> 0.2" ],
    }
    dep_types.sort { |a,b| a.to_s <=> b.to_s }.each do |dep, dep_args|
      check_with = dep_args.shift
      describe dep do
        it "should be set-able via #{dep}" do
          @meta.send(dep, *dep_args).should == [dep_args[1]]
        end
        it "should be get-able via #{check_with}" do
          @meta.send(dep, *dep_args)
          @meta.send(check_with).should == { dep_args[0] => [dep_args[1]] }
        end
      end
    end
  end

  describe "cookbook attributes" do
    it "should allow you set an attributes metadata" do
      attrs = {
        "display_name" => "MySQL Databases",
        "multiple_values" => true,
        "type" => 'string',
        "required" => false,
        "recipes" => [ "mysql::server", "mysql::master" ],
        "default" => [ ]
      }
      @meta.attribute("/db/mysql/databases", attrs).should == attrs
    end

    it "should not accept anything but a string for display_name" do
      lambda {
        @meta.attribute("db/mysql/databases", :display_name => "foo")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :display_name => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should not accept anything but a string for the description" do
      lambda {
        @meta.attribute("db/mysql/databases", :description => "foo")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :description => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should let multiple_values be true or false" do
      lambda {
        @meta.attribute("db/mysql/databases", :multiple_values => true)
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :multiple_values => false)
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :multiple_values => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should set multiple_values to false by default" do
      @meta.attribute("db/mysql/databases", {})
      @meta.attributes["db/mysql/databases"][:multiple_values].should == false
    end

    it "should let type be string, array or hash" do
      lambda {
        @meta.attribute("db/mysql/databases", :type => "string")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :type => "array")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :type => "hash")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :type => Array.new)
      }.should raise_error(ArgumentError)
    end

    it "should let required be true or false" do
      lambda {
        @meta.attribute("db/mysql/databases", :required => true)
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :required => false)
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :required => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should set required to false by default" do
      @meta.attribute("db/mysql/databases", {})
      @meta.attributes["db/mysql/databases"][:required].should == false
    end

    it "should make sure recipes is an array" do
      lambda {
        @meta.attribute("db/mysql/databases", :recipes => [])
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :required => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should set recipes to an empty array by default" do
      @meta.attribute("db/mysql/databases", {})
      @meta.attributes["db/mysql/databases"][:recipes].should == [] 
    end

    it "should allow the default value to be a string, array, or hash" do
      lambda {
        @meta.attribute("db/mysql/databases", :default => [])
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :default => {})
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :default => "alice in chains")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :required => :not_gonna_do_it)
      }.should raise_error(ArgumentError)
    end

  end

  describe "checking version expression" do
    it "should accept >> 8.04" do
      @meta._check_version_expression(">> 8.04").should == [ ">>", "8.04" ]
    end

    it "should accept >= 8.04" do
      @meta._check_version_expression(">= 8.04").should == [ ">=", "8.04" ]
    end

    it "should accept = 8.04" do
      @meta._check_version_expression("= 8.04").should == [ "=", "8.04" ]
    end

    it "should accept <= 8.04" do
      @meta._check_version_expression("<= 8.04").should == [ "<=", "8.04" ]
    end

    it "should accept << 8.04" do
      @meta._check_version_expression("<< 8.04").should == [ "<<", "8.04" ]
    end

    it "should raise an exception on an invalid version expression" do
      lambda {
        @meta._check_version_expression("tried to << love you")
      }.should raise_error(ArgumentError)
    end
  end

  describe "check for a valid version" do
    it "should think 8.00 is << 8.04" do
      @meta._check_valid_version("8.00", "<< 8.04").should == true
    end

    it "should think 9.04 is not << 8.04" do
      @meta._check_valid_version("9.04", "<< 8.04").should == false 
    end

    it "should think 8.00 is <= 8.04" do
      @meta._check_valid_version("8.00", "<= 8.04").should == true
    end

    it "should think 8.04 is <= 8.04" do
      @meta._check_valid_version("8.04", "<= 8.04").should == true
    end

    it "should think 9.04 is not <= 8.04" do
      @meta._check_valid_version("9.04", "<= 8.04").should == false 
    end

    it "should think 8.00 is not = 8.04" do
      @meta._check_valid_version("8.00", "= 8.04").should == false 
    end

    it "should think 8.04 is = 8.04" do
      @meta._check_valid_version("8.04", "= 8.04").should == true
    end

    it "should think 8.00 is not >= 8.04" do
      @meta._check_valid_version("8.00", ">= 8.04").should == false 
    end

    it "should think 9.04 is >= 8.04" do
      @meta._check_valid_version("9.04", ">= 8.04").should == true
    end

    it "should think 8.04 is >= 8.04" do
      @meta._check_valid_version("8.04", ">= 8.04").should == true
    end

    it "should think 8.00 is not >> 8.04" do
      @meta._check_valid_version("8.00", ">> 8.04").should == false 
    end

    it "should think 8.04 is not >> 8.04" do
      @meta._check_valid_version("8.04", ">> 8.04").should == false 
    end

    it "should think 9.04 is >> 8.04" do
      @meta._check_valid_version("9.04", ">> 8.04").should == true
    end
  end

  describe "recipes" do
    before(:each) do 
      @cookbook.recipe_files = [ "default.rb", "enlighten.rb" ]
      @meta = Chef::Cookbook::Metadata.new(@cookbook)
    end
    
    it "should have the names of the recipes" do
      @meta.recipes["test_cookbook"].should == ""
      @meta.recipes["test_cookbook::enlighten"].should == ""
    end

    it "should let you set the description for a recipe" do
      @meta.recipe "test_cookbook", "It, um... tests stuff?"
      @meta.recipes["test_cookbook"].should == "It, um... tests stuff?"
    end

    it "should automatically provide each recipe" do
      @meta.providing.has_key?("test_cookbook").should == true
      @meta.providing.has_key?("test_cookbook::enlighten").should == true
    end

  end

  describe "json" do
    before(:each) do 
      @cookbook.recipe_files = [ "default.rb", "enlighten.rb" ]
      @meta = Chef::Cookbook::Metadata.new(@cookbook)
      @meta.version "1.0"
      @meta.maintainer "Bobo T. Clown"
      @meta.maintainer_email "bobo@example.com"
      @meta.long_description "I have a long arm!"
      @meta.supports :ubuntu, ">> 8.04"
      @meta.depends "bobo", "= 1.0"
      @meta.depends "bobotclown", "= 1.1"
      @meta.recommends "snark", "<< 3.0"
      @meta.suggests "kindness", ">> 2.0", "<< 4.0"
      @meta.conflicts "hatred"
      @meta.provides "foo(:bar, :baz)"
      @meta.replaces "snarkitron"
      @meta.recipe "test_cookbook::enlighten", "is your buddy"
      @meta.attribute "bizspark/has_login", 
        :display_name => "You have nothing" 
    end
 
    describe "serialize" do
      before(:each) do
        @serial = JSON.parse(@meta.to_json)
      end

      it "should serialize to a json hash" do
        JSON.parse(@meta.to_json).should be_a_kind_of(Hash)
      end

      %w{
        name 
        description 
        long_description 
        maintainer 
        maintainer_email 
        license
        platforms 
        dependencies 
        suggestions 
        recommendations 
        conflicting 
        providing
        replacing 
        attributes 
        recipes
      }.each do |t| 
        it "should include '#{t}'" do
          @serial[t].should == @meta.send(t.to_sym)
        end
      end
    end

    describe "deserialize" do
      before(:each) do
        @deserial = Chef::Cookbook::Metadata.from_json(@meta.to_json)
      end

      it "should deserialize to a Chef::Cookbook::Metadata object" do
        @deserial.should be_a_kind_of(Chef::Cookbook::Metadata)
      end

      %w{
        name 
        description 
        long_description 
        maintainer 
        maintainer_email 
        license
        platforms 
        dependencies 
        suggestions 
        recommendations 
        conflicting 
        providing
        replacing 
        attributes 
        recipes
      }.each do |t| 
        it "should match '#{t}'" do
          @deserial.send(t.to_sym).should == @meta.send(t.to_sym)
        end
      end

    end

  end

end
