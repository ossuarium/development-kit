require 'spec_helper'

describe Kit::Bit::Environment do

  let(:site_1) { create :bit, name: 'site_1' }
  let(:site_2) { create :bit, name: 'site_2' }

  subject(:environment) { Kit::Bit::Environment.new }

  after :all do
    Dir.glob("#{Kit::Bit::Environment.new.options[:tmp_dir]}/#{Kit::Bit::Environment.new.options[:dir_prefix]}*").each do |dir|
      FileUtils.remove_entry_secure dir
    end
  end

  describe ".new" do

    it "should set default options" do
      expect(environment.options).to eq Kit::Bit::Environment::DEFAULT_OPTIONS
    end

    it "should merge default options" do
      environment = Kit::Bit::Environment.new options: { tmp_dir: '/tmp/path' }
      expect(environment.options).to eq Kit::Bit::Environment::DEFAULT_OPTIONS.merge(tmp_dir: '/tmp/path')
    end
  end

  describe "#options=" do

    it "should merge with default options" do
      environment.options[:tmp_dir] = '/tmp/path'
      expect(environment.options).to eq Kit::Bit::Environment::DEFAULT_OPTIONS.merge(tmp_dir: '/tmp/path')
    end
  end

  describe "#site" do

    it "must be a Kit::Bit" do
      expect { environment.site = 'site_1' }.to raise_error TypeError
    end

    it "cannot be redefinfed while populated" do
      environment.site = site_1
      allow(environment).to receive(:populated).and_return(true)
      expect { environment.site = site_2 }.to raise_error RuntimeError, /populated/
    end
  end

  describe "#treeish" do

    it "must be a string" do
      expect { environment.treeish = 1 }.to raise_error TypeError
    end

    it "cannot be redefinfed while populated" do
      environment.treeish = 'treeish_1'
      allow(environment).to receive(:populated).and_return(true)
      expect { environment.treeish = 'treeish_2' }.to raise_error RuntimeError, /populated/
    end
  end

  describe "#directory" do

    context "when required values set" do

      subject(:environment) { Kit::Bit::Environment.new site: site_1 }

      before :each do
        allow(Kit::Bit::Utility).to receive(:make_random_directory).and_return('/tmp/rand_dir')
      end

      context "when directory is unset" do

        it "makes and returns a random directory" do
          expect(environment.directory).to eq '/tmp/rand_dir'
        end
      end

      context "when directory is set" do

        it "returns the current directory" do
          expect(Kit::Bit::Utility).to receive(:make_random_directory).once
          environment.directory
          expect(environment.directory).to eq '/tmp/rand_dir'
        end
      end
    end

    context "when required values are not set" do

      it "fails if site is not set" do
        expect { environment.directory }.to raise_error RuntimeError
      end
    end
  end

  describe "#cleanup" do

    subject(:environment) { Kit::Bit::Environment.new site: site_1 }

    it "removes the directory and resets @directory" do
      environment.directory
      FileUtils.should_receive(:remove_entry_secure).with(environment.directory)
      environment.cleanup
      expect(environment.instance_variable_get :@directory).to eq nil
    end
  end

  describe "#populate" do

    context "required values set" do

      subject(:environment) { Kit::Bit::Environment.new site: site_1, treeish: 'master' }

      before :each do
        allow(site_1).to receive(:repo).and_return(double Grit::Repo)
      end

      it "will cleanup if populated" do
        allow(Kit::Bit::Utility).to receive :extract_repo
        environment.populate
        expect(environment).to receive :cleanup
        environment.populate
      end

      it "extracts the repo to the directory and sets populated true" do
        expect(Kit::Bit::Utility).to receive(:extract_repo).with(site_1.repo, 'master', environment.directory)
        environment.populate
        expect(environment.populated).to eq true
      end
    end

    context "missing required values" do

      it "fails when missing site" do
        environment.treeish = 'master'
        expect { environment.populate }.to raise_error RuntimeError, /populate without/
      end

      it "fails when missing treeish" do
        environment.site = site_1
        environment.treeish = ''
        expect { environment.populate }.to raise_error RuntimeError, /populate without/
      end
    end
  end

  describe "config" do

    subject(:environment) { Kit::Bit::Environment.new site: site_1, treeish: 'master' }

    it "cannot load config if not populated" do
      expect { environment.config }.to raise_error RuntimeError
    end

    it "loads the config if populated" do
      allow(environment).to receive(:populated).and_return(true)
      expect(YAML).to receive(:load_file).with("#{environment.directory}/development_config.yml")
      environment.config
    end
  end
end
