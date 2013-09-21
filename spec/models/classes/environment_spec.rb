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

    it "sets default options" do
      expect(environment.options).to eq Kit::Bit::Environment::DEFAULT_OPTIONS
    end

    it "merges default options" do
      environment = Kit::Bit::Environment.new options: { tmp_dir: '/tmp/path' }
      expect(environment.options).to eq Kit::Bit::Environment::DEFAULT_OPTIONS.merge(tmp_dir: '/tmp/path')
    end
  end

  describe "#options" do

    it "merges with default options" do
      environment.options[:tmp_dir] = '/tmp/path'
      expect(environment.options).to eq Kit::Bit::Environment::DEFAULT_OPTIONS.merge(tmp_dir: '/tmp/path')
    end

    it "can be called twice and merge options" do
      environment.options[:tmp_dir] = '/tmp/path'
      environment.options[:dir_prefix] = '/tmp/path'
      expect(environment.options).to eq Kit::Bit::Environment::DEFAULT_OPTIONS.merge(tmp_dir: '/tmp/path', dir_prefix: '/tmp/path')
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

    before :each do
      allow(YAML).to receive(:load_file)
    end

    it "populate if not populated" do
      expect(environment).to receive :populate
      environment.config
    end

    it "populate only if not populated" do
      allow(environment).to receive(:populated).and_return(true)
      expect(environment).not_to receive :populate
      environment.config
    end

    it "loads the config if populated" do
      allow(environment).to receive(:populated).and_return(true)
      expect(YAML).to receive(:load_file).with("#{environment.directory}/development-kit_config.yml")
      environment.config
    end
  end

  describe "methods that modify the working directory" do

    let(:config) do
      YAML.load <<-EOF
        :assets:
          :output: compiled
          :src_pre: "(%"
          :sources:
            - public
            - app/src
          :javascripts:
            :options:
              :js_compressor: :uglifier
              :gzip: true
            :paths:
              - assets/javascripts
              - other/javascripts
          :stylesheets:
            :options:
              :output: css
              :css_compressor: :sass
            :paths:
              - assets/stylesheets
      EOF
    end

    before :each do
      environment.site = site_1
      environment.directory
      allow(environment).to receive(:populated).and_return(true)
      allow(environment).to receive(:config).and_return(config)
    end

    describe "#assets" do

      subject(:assets) { environment.assets }

      it "returns an array" do
        expect(assets).to be_a Array
      end

      it "returns an array of asset objects" do
        expect(assets[0]).to be_a Kit::Bit::Assets
        expect(assets[1]).to be_a Kit::Bit::Assets
      end

      it "sets the directory for each asset" do
        expect(assets[0].directory).to eq environment.directory
        expect(assets[1].directory).to eq environment.directory
      end

      it "sets the options for each asset" do
        expect(assets[0].options).to include output: 'compiled'
        expect(assets[0].options).to include js_compressor: :uglifier
        expect(assets[0].options).to include gzip: true
        expect(assets[1].options).to include output: 'css'
        expect(assets[1].options).to include css_compressor: :sass
      end

      it "sets the paths for each asset" do
        expect(assets[0].paths).to include 'assets/javascripts'
        expect(assets[0].paths).to include 'other/javascripts'
        expect(assets[1].paths).to include 'assets/stylesheets'
      end

      it "only loads the paths for each type of asset" do
        expect(assets[0].paths).to_not include 'assets/stylesheets'
        expect(assets[1].paths).to_not include 'assets/javascripts'
      end

      it "does not fail if assets are not configured" do
        allow(environment).to receive(:config).and_return({})
        expect { assets }.not_to raise_error
      end
    end

    describe "#sources_with_assets" do

      let(:dir) { environment.directory }

      it "looks for all asset types" do
        expect(Kit::Bit::Assets).to receive(:find_tags).twice.with(anything, nil, anything)
        environment.sources_with_assets
      end

      it "uses options as options" do
        expect(Kit::Bit::Assets).to receive(:find_tags).twice.with(anything, anything, { src_pre: '(%' } )
        environment.sources_with_assets
      end

      it "returns assets with tags" do
        allow(Kit::Bit::Assets).to receive(:find_tags).with(dir + '/public', anything, anything).and_return(dir + '/public/header.html')
        allow(Kit::Bit::Assets).to receive(:find_tags).with(dir + '/app/src', anything, anything).and_return(dir + '/app/src/head.tpl')
        expect(environment.sources_with_assets).to eq [ "#{dir}/public/header.html", "#{dir}/app/src/head.tpl" ]
      end
    end

    describe "#compile_assets" do

      let(:sources) { [ "#{environment.directory}/public/header.html", "#{environment.directory}/app/src/head.tpl" ] }

      it "compiles the assets and writes the sources" do
        allow(environment).to receive(:sources_with_assets).and_return sources
        allow(File).to receive(:read).with(sources[0]).and_return('data_1')
        allow(File).to receive(:read).with(sources[1]).and_return('data_2')
        expect(Kit::Bit::Utility).to receive(:write).with 'data_1', sources[0]
        expect(Kit::Bit::Utility).to receive(:write).with 'data_2', sources[1]
        environment.compile_assets
      end
    end
  end
end
