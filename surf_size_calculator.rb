
module ForecastDownloader

  class SurfSizeCalculator
    
    G =  9.81 #m/s
    
    def calculate(h_0,p)
      h_b = ( h_0**(4.0/5.0) ) * (((1/(Math.sqrt(G))))*(G*p/4*Math::PI))**(2.0/5.0) 
      h_surf =  h_b * k_r(h_b) * 0.50
    end
    
    def k_r(hb)
      -0.0013*(hb**2) + 0.1262*hb + 0.3025
    end

  end

  #FIXME: Move me or rename the file (Actually rename and move the file)
  class SwellClassCalculator
    
    def calculate(ss,sp)
      ss*sp
    end    
  end
  
end


