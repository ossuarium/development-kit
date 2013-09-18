require 'spec_helper'

describe Kit::Bit::Environment do

  let(:site_1) { create :bit, name: 'site_1' }
  let(:site_2) { create :bit, name: 'site_2' }

  subject(:env) { Kit::Bit::Environment.new }

  after :all do
    Dir.glob("#{Kit::Bit::Environment::TMP_DIR}/#{Kit::Bit::Environment::DIR_PREFIX}*").each do |dir|
      FileUtils.remove_entry_secure dir
    end
  end

  describe ".new" do

    it "creates a new empty object" do
      env = Kit::Bit::Environment.new
      expect(env).to be_an_instance_of Kit::Bit::Environment
      expect(env.site).to be_nil
      expect(env.treeish).to be_nil
    end

    it "creates a new object with site" do
      env = Kit::Bit::Environment.new site: site_1
      expect(env.site).to equal site_1
    end

    it "creates a new object with treeish" do
      env = Kit::Bit::Environment.new treeish: 'master'
      expect(env.treeish ).to eq 'master'
    end
  end

  describe "#site" do

    it "must be a Kit::Bit" do
      expect { env.site = 'site_1' }.to raise_error TypeError
    end

    it "cannot be redefinfed" do
      env.site = site_1
      expect { env.site = site_2 }.to raise_error RuntimeError
    end
  end

  describe "#treeish" do

    it "must be a string" do
      expect { env.treeish = 1 }.to raise_error TypeError
    end

    it "cannot be redefinfed" do
      env.treeish = 'treeish_1'
      expect { env.treeish = 'treeish_2' }.to raise_error RuntimeError
    end
  end

  describe "#directory" do

    context "when required values set" do

      subject(:env) { Kit::Bit::Environment.new site: site_1 }

      before :each do
        Kit::Bit::Utility.stub(:make_random_directory).and_return('/tmp/rand_dir')
      end

      context "when directory is unset" do

        it "makes and returns a random directory" do
          expect(env.directory).to eq '/tmp/rand_dir'
        end
      end

      context "when directory is set" do

        it "returns the current directory" do
          expect(Kit::Bit::Utility).to receive(:make_random_directory).once
          env.directory
          expect(env.directory).to eq '/tmp/rand_dir'
        end
      end
    end

    context "when required values are not set" do

      it "fails if site is not set" do
        expect { env.directory }.to raise_error RuntimeError
      end
    end
  end

  describe "#cleanup" do

    subject(:env) { Kit::Bit::Environment.new site: site_1 }

    it "removes the directory and resets @directory" do
      env.directory
      FileUtils.should_receive(:remove_entry_secure).with(env.directory)
      env.cleanup
      expect(env.instance_variable_get :@directory).to eq nil
    end
  end

  describe "#populate" do

    context "required values set" do

      subject(:env) { Kit::Bit::Environment.new site: site_1, treeish: 'master' }

      before :each do
        site_1.stub(:repo).and_return(double Grit::Repo)
      end

      it "will cleanup if populated" do
        Kit::Bit::Utility.stub(:extract_repo)
        env.populate
        expect(env).to receive :cleanup
        env.populate
      end

      it "extracts the repo to the directory and sets populated true" do
        expect(Kit::Bit::Utility).to receive(:extract_repo).with(site_1.repo, 'master', env.directory)
        env.populate
        expect(env.populated).to eq true
      end
    end

    context "missing required values" do

      it "fails when missing site" do
        env.treeish = 'master'
        expect { env.populate }.to raise_error RuntimeError
      end

      it "fails when missing treeish" do
        env.site = site_1
        expect { env.populate }.to raise_error RuntimeError
      end
    end
  end

  describe "config" do

    subject(:env) { Kit::Bit::Environment.new site: site_1, treeish: 'master' }

    it "cannot load config if not populated" do
      expect { env.config }.to raise_error RuntimeError
    end

    it "loads the config if populated" do
      env.stub(:populated).and_return(true)
      expect(YAML).to receive(:load_file).with("#{env.directory}/development_config.yml")
      env.config
    end
  end
end
