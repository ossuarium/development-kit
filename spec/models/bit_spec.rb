require 'spec_helper'

describe Kit::Bit do

  let(:group) { create :group, name: 'app', repository: '/path/to/repo' }
  let(:production) { create :bit, name: 'production', group: group, root_domain: 'www.example.com' }
  let(:beta) { create :bit, name: 'beta', group: group, root_domain: 'example.com' }

  describe "#repo" do

    it "creates a new grit repo object with the correct path" do
      Grit::Repo.should_receive(:new).with('/path/to/repo')
      production.repo
    end
  end

  describe "#domain" do

    it "returns the base domain for the special site name 'production'" do
      expect(production.domain).to eq 'www.example.com'
    end

    it "returns a sub domain for a non-production site" do
      expect(beta.domain).to eq 'beta.example.com'
    end
  end
end
