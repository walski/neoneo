require File.join(File.dirname(__FILE__), 'spec_helper')

describe Babylon do
  it "should raise an Babylon::Error on erroneous Google response" do
    Babylon.should_receive(:get).and_return({"responseStatus"=>400, "responseDetails"=>nil})

    begin
      Babylon.language_of("Text that causes an error")
    rescue Babylon::Error
    else
      flunk 'Should raise an Babylon::Error'
    end
  end
  
  it "should raise an Babylon::UncertaintyError if the text can not be clearly determined an reliability is demanded" do
    Babylon.should_receive(:get).and_return({"responseData"=>{"language"=>"en", "confidence"=>0.1771214, "isReliable"=>false}, "responseStatus"=>200, "responseDetails"=>nil})

    begin
      Babylon.language_of("Undeterminable text", :ensure_reliability => true)
    rescue Babylon::UncertaintyError
    else
      flunk 'Should raise an Babylon::UncertaintyError'
    end
  end
  
  it "should raise no Babylon::UncertaintyError if the certainty equals the demanded one" do
    Babylon.should_receive(:get).and_return({"responseData"=>{"language"=>"en", "confidence"=>0.20, "isReliable"=>true}, "responseStatus"=>200, "responseDetails"=>nil})
    Babylon.language_of("Undeterminable text", :min_certainty => 0.20)
  end
  
  it "should raise no Babylon::UncertaintyError if the certainty is above the demanded one" do
    Babylon.should_receive(:get).and_return({"responseData"=>{"language"=>"en", "confidence"=>0.201, "isReliable"=>true}, "responseStatus"=>200, "responseDetails"=>nil})
    Babylon.language_of("Undeterminable text", :min_certainty => 0.20)
  end

  it "should raise Babylon::UncertaintyError if the certainty is below the demanded one" do
    Babylon.should_receive(:get).and_return({"responseData"=>{"language"=>"en", "confidence"=>0.209, "isReliable"=>true}, "responseStatus"=>200, "responseDetails"=>nil})
    begin
      Babylon.language_of("Undeterminable text", :min_certainty => 0.21)
    rescue Babylon::UncertaintyError
    else
      flunk 'Should raise an Babylon::UncertaintyError'
    end
  end
end
