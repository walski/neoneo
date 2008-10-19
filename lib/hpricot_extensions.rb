module Hpricot
  class Text
    def clean
      self.to_s.chomp.strip
    end
  end
  
  class Elem
    def clean
      innerText.chomp.strip
    end
  end
end