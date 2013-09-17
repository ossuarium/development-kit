require 'spec_helper'

describe Kit::Bit::Environment do

  let(:site_1) { create :bit, name: 'site_1' }
  let(:site_2) { create :bit, name: 'site_2' }

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

    subject(:env) { Kit::Bit::Environment.new }

    it "must be a Kit::Bit" do
      expect { env.site = 'site_1' }.to raise_error TypeError
    end

    it "cannot be redefinfed" do
      env.site = site_1
      expect { env.site = site_2 }.to raise_error RuntimeError
    end
  end

  describe "#treeish" do

    subject(:env) { Kit::Bit::Environment.new }

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

      context "when directory is unset" do

        it "makes and returns a random directory" do
          Kit::Bit::Utility.stub(:make_random_directory).and_return('/tmp/rand_dir')
          expect(env.directory).to eq '/tmp/rand_dir'
        end
      end

      context "when directory is set" do

        it "returns the current directory" do
          Kit::Bit::Utility.stub(:make_random_directory).and_return('/tmp/rand_dir')
          expect(Kit::Bit::Utility).to receive(:make_random_directory).once
          env.directory
          expect(env.directory).to eq '/tmp/rand_dir'
        end
      end
    end

    context "when required values are not set" do

      subject(:env) { Kit::Bit::Environment.new }

      it "fails if site is not set" do
        expect { env.directory }.to raise_error RuntimeError
      end
    end

  end

  describe "#cleanup" do

    subject(:env) { Kit::Bit::Environment.new site: site_1 }

    it "removes the directory and resets @directory" do
      env.stub(:directory).and_return('/tmp/rand_dir')
      FileUtils.should_receive(:remove_entry_secure).with('/tmp/rand_dir')
      env.cleanup
      expect(env.instance_variable_get :@directory).to eq nil
    end
  end

  describe "#populate" do

    context "required values set" do

      subject(:env) { Kit::Bit::Environment.new site: site_1, treeish: 'master' }

      it "extracts the repo to the directory" do
        site_1.stub(:repo).and_return(double Grit::Repo)
        env.stub(:directory).and_return('/tmp/rand_dir')
        expect(Kit::Bit::Utility).to receive(:extract_repo).with(site_1.repo, 'master', '/tmp/rand_dir')
        env.populate
      end

    end

    context "missing required values" do

      subject(:env) { Kit::Bit::Environment.new }

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
end
