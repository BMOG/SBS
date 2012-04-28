module Service

# provide stand alone services: *must* not have any model, view or controller dependencies 
  
  # returns an uncompressed list of directions from the corresponding xml token 
  def Service.uncompressed_directions(s) 
    directions = ""
    s.split(',').each do |meta_direction|
      if meta_direction.byteslice(0) == '(' then
        Integer(meta_direction.byteslice(-1)).times do
          meta_direction [1, meta_direction.rindex(')') - 1].split(';').each do |direction|
            directions << "#{direction},"  
          end
        end
      else
        directions << "#{meta_direction},"  
      end
    end
    return directions.chop
  end 

end