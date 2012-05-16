module Service

# provide stand alone services: *must* not have any model, view or controller dependencies 
  
  # returns an uncompressed list of directions from the corresponding xml token 
  def Service.uncompressed_directions(p_string) 
    directions = ""
    p_string.split(',').each do |meta_direction|
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

  # returns an uncompressed list of hexagons from the corresponding xml token 
  def Service.uncompressed_hexagons(p_string) 
    hexagons = ""
    p_string.split(',').each do |meta_hexagon|
      if meta_hexagon.size == 5 then
        hexagons << "#{meta_hexagon},"  
      else
        for i in meta_hexagon.split('-').first.split(';').first.to_i..meta_hexagon.split('-').last.split(';').first.to_i do
          i.to_s.size == 1 ? column = "0#{i.to_s}" : column = i.to_s 
          hexagons << "#{column};#{meta_hexagon.split('-').last.split(';').last}," 
        end
      end
    end
    return hexagons.chop
  end 

end 