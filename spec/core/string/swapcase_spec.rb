# -*- encoding: utf-8 -*-
# frozen_string_literal: false
require_relative '../../spec_helper'
require_relative 'fixtures/classes'

describe "String#swapcase" do
  it "returns a new string with all uppercase chars from self converted to lowercase and vice versa" do
    "Hello".swapcase.should == "hELLO"
    "cYbEr_PuNk11".swapcase.should == "CyBeR_pUnK11"
    "+++---111222???".swapcase.should == "+++---111222???"
  end

  it "returns a String in the same encoding as self" do
    "Hello".encode("US-ASCII").swapcase.encoding.should == Encoding::US_ASCII
  end

  describe "full Unicode case mapping" do
    it "works for all of Unicode with no option" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        "äÖü".swapcase.should == "ÄöÜ"
      end
    end

    it "updates string metadata" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        swapcased = "Aßet".swapcase

        swapcased.should == "aSSET"
        swapcased.size.should == 5
        swapcased.bytesize.should == 5
        swapcased.ascii_only?.should be_true
      end
    end
  end

  describe "ASCII-only case mapping" do
    it "does not swapcase non-ASCII characters" do
      "aßet".swapcase(:ascii).should == "AßET"
    end

    it "works with substrings" do
      "prefix aTé"[-3..-1].swapcase(:ascii).should == "Até"
    end
  end

  describe "full Unicode case mapping adapted for Turkic languages" do
    it "swaps case of ASCII characters according to Turkic semantics" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        "aiS".swapcase(:turkic).should == "Aİs"
      end
    end

    it "allows Lithuanian as an extra option" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        "aiS".swapcase(:turkic, :lithuanian).should == "Aİs"
      end
    end

    it "does not allow any other additional option" do
      -> { "aiS".swapcase(:turkic, :ascii) }.should raise_error(ArgumentError)
    end
  end

  describe "full Unicode case mapping adapted for Lithuanian" do
    it "currently works the same as full Unicode case mapping" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        "Iß".swapcase(:lithuanian).should == "iSS"
      end
    end

    it "allows Turkic as an extra option (and applies Turkic semantics)" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        "iS".swapcase(:lithuanian, :turkic).should == "İs"
      end
    end

    it "does not allow any other additional option" do
      -> { "aiS".swapcase(:lithuanian, :ascii) }.should raise_error(ArgumentError)
    end
  end

  it "does not allow the :fold option for upcasing" do
    -> { "abc".swapcase(:fold) }.should raise_error(ArgumentError)
  end

  it "does not allow invalid options" do
    -> { "abc".swapcase(:invalid_option) }.should raise_error(ArgumentError)
  end

  it "returns String instances when called on a subclass" do
    StringSpecs::MyString.new("").swapcase.should be_an_instance_of(String)
    StringSpecs::MyString.new("hello").swapcase.should be_an_instance_of(String)
  end
end

describe "String#swapcase!" do
  it "modifies self in place" do
    a = "cYbEr_PuNk11"
    a.swapcase!.should equal(a)
    a.should == "CyBeR_pUnK11"
  end

  it "modifies self in place for non-ascii-compatible encodings" do
    a = "cYbEr_PuNk11".encode("utf-16le")
    a.swapcase!
    a.should == "CyBeR_pUnK11".encode("utf-16le")
  end

  describe "full Unicode case mapping" do
    it "modifies self in place for all of Unicode with no option" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        a = "äÖü"
        a.swapcase!
        a.should == "ÄöÜ"
      end
    end

    it "works for non-ascii-compatible encodings" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        a = "äÖü".encode("utf-16le")
        a.swapcase!
        a.should == "ÄöÜ".encode("utf-16le")
      end
    end

    it "updates string metadata" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        swapcased = "Aßet"
        swapcased.swapcase!

        swapcased.should == "aSSET"
        swapcased.size.should == 5
        swapcased.bytesize.should == 5
        swapcased.ascii_only?.should be_true
      end
    end
  end

  describe "modifies self in place for ASCII-only case mapping" do
    it "does not swapcase non-ASCII characters" do
      a = "aßet"
      a.swapcase!(:ascii)
      a.should == "AßET"
    end

    it "works for non-ascii-compatible encodings" do
      a = "aBc".encode("utf-16le")
      a.swapcase!(:ascii)
      a.should == "AbC".encode("utf-16le")
    end
  end

  describe "modifies self in place for full Unicode case mapping adapted for Turkic languages" do
    it "swaps case of ASCII characters according to Turkic semantics" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        a = "aiS"
        a.swapcase!(:turkic)
        a.should == "Aİs"
      end
    end

    it "allows Lithuanian as an extra option" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        a = "aiS"
        a.swapcase!(:turkic, :lithuanian)
        a.should == "Aİs"
      end
    end

    it "does not allow any other additional option" do
      -> { a = "aiS"; a.swapcase!(:turkic, :ascii) }.should raise_error(ArgumentError)
    end
  end

  describe "full Unicode case mapping adapted for Lithuanian" do
    it "currently works the same as full Unicode case mapping" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        a = "Iß"
        a.swapcase!(:lithuanian)
        a.should == "iSS"
      end
    end

    it "allows Turkic as an extra option (and applies Turkic semantics)" do
      NATFIXME 'Pending unicode casemap support', exception: SpecFailedException do
        a = "iS"
        a.swapcase!(:lithuanian, :turkic)
        a.should == "İs"
      end
    end

    it "does not allow any other additional option" do
      -> { a = "aiS"; a.swapcase!(:lithuanian, :ascii) }.should raise_error(ArgumentError)
    end
  end

  it "does not allow the :fold option for upcasing" do
    -> { a = "abc"; a.swapcase!(:fold) }.should raise_error(ArgumentError)
  end

  it "does not allow invalid options" do
    -> { a = "abc"; a.swapcase!(:invalid_option) }.should raise_error(ArgumentError)
  end

  it "returns nil if no modifications were made" do
    a = "+++---111222???"
    a.swapcase!.should == nil
    a.should == "+++---111222???"

    "".swapcase!.should == nil
  end

  it "raises a FrozenError when self is frozen" do
    ["", "hello"].each do |a|
      a.freeze
      -> { a.swapcase! }.should raise_error(FrozenError)
    end
  end
end
