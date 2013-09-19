require 'spec_helper'

describe Kit::Bit do

  let(:bit) { create :bit, name: 'bit name' }

  describe "#name" do
    it "returns the bit name" do
      expect(bit.name).to eq 'bit name'
    end
  end
end
