# == Schema Information
#
# Table name: grids
#
#  id              :integer         not null, primary key
#  scenario_id     :integer
#  picture_width   :integer
#  picture_height  :integer
#  maxcol          :integer
#  maxlin          :integer
#  hex_side_length :integer
#  created_at      :datetime
#  updated_at      :datetime
#

class Grid < ActiveRecord::Base

  # returns a string of x,y coordinates drawing a polyline along vertices from a xml bloc
  def get_polyline_on_edges(h)
    # initialize with the given hash
    hcl = h ["hexagone_depart"].split(';')
    hexagon = hn_from_hcl(hcl.first.to_i, hcl.last.to_i) 
    vertex = h ["angle_depart"]
    directions = Service.uncompressed_directions(h ["liste_directions"])
    # provide the beginning of the polyline
    polyline_points = "#{x_vertex(hexagon, vertex)},#{y_vertex(hexagon, vertex)} "
    # for each direction, find the new hexagon and vertex, then provide the next set of coordinates
logger.debug "hcl: #{hcl}, hexagon: #{hexagon}, vertex: #{vertex}, polyline_points: #{polyline_points}"
    directions.split(',').each do |direction|
logger.debug "direction + vertex: #{direction}#{vertex}"      
      case direction + vertex
        when "NN", "NONE"   then hexagon = adjacent(hexagon, "NE") 
        when "NENE", "NSE"  then hexagon = adjacent(hexagon, "E") 
        when "NES", "SESE"  then hexagon = adjacent(hexagon, "SE") 
        when "SS", "SESO"   then hexagon = adjacent(hexagon, "SO") 
        when "SNO", "SOSO"  then hexagon = adjacent(hexagon, "O") 
        when "SON", "NONO"  then hexagon = adjacent(hexagon, "NO")
      end   
      vertex = case direction
        when "N"  then "NO"       
        when "NE" then "N"      
        when "SE" then "NE"      
        when "S"  then "SE"      
        when "SO" then "S"      
        when "NO" then "SO"
      end          
      polyline_points << "#{x_vertex(hexagon, vertex)},#{y_vertex(hexagon, vertex)} "
logger.debug "hexagon: #{hexagon}, vertex: #{vertex}, polyline_points: #{polyline_points}"
    end
    # and return the string of coordinates
    return polyline_points.chop
  end

# CANDIDAT A UN TRASFERT DANS LA CLASSE hEXAGONE
  # returns the hexagon (number) adjacent to the given hexagon in the given direction
  # returns -1 if there is no adjacent hexagon in the given direction 
  def adjacent(hexagon, direction)
    hexcol = hc_from_hn(hexagon)
    hexlin = hl_from_hn(hexagon)
    case direction
      when "NE"
        hexcol += 1 if hexlin%2 != 0
        hexlin -= 1
      when "E"
        hexcol += 1
      when "SE"
        hexcol += 1 if hexlin%2 != 0
        hexlin += 1
      when "SO"
        hexcol -= 1 if hexlin%2 == 0
        hexlin += 1
      when "O"
        hexcol -= 1
      when "NO"
        hexcol -= 1 if hexlin%2 == 0
        hexlin -= 1
    end
    # adjust for off grid situations
    if hexlin < 0 or hexlin >= maxlin or hexcol < 0 or hexcol >= (maxcol - hexlin%2)  then
      return -1
    else  
      return hn_from_hcl(hexcol, hexlin)
    end  
  end
    
  # returns the central hexagon number of the grid
  def central_hexagon_number
    return hn_from_hcl(((maxcol - 1) / 2).floor, (maxlin / 2).floor)
  end 

  # returns the x translation from the context
  # dictionary
  # xcch: x coordinate of the canvas central hexagon
  # amw: adjusted map width
  def x_translation(context)
    xcch = (context.cw / 2).floor - (rhl * context.scale).floor
    amw = (picture_width * context.scale).floor
    xt = xcch - (xp_from_hn(context.current_hex) * context.scale).floor
    if amw < context.cw then
      xt = (context.cw - amw) / 2 
    elsif xt > 0 then
      xt = 0
    elsif (xt + amw) < context.cw then
      xt = context.cw - amw
    end 
    return xt / context.scale
  end

  # returns the y translation from the context
  # dictionary
  # ycch: y coordinate of the canvas central hexagon
  # amh: adjusted map height
  def y_translation(context)
    ycch = (context.ch / 2).floor - ((th + rhl / 2) * context.scale).floor
    amh = (picture_height * context.scale).floor
    yt = ycch - (yp_from_hn(context.current_hex) * context.scale).floor
    if amh < context.ch then
      yt = (context.ch - amh) / 2
    elsif yt > 0 then
      yt = 0
    elsif (yt + amh) < context.ch then
      yt = context.ch - amh
    end 
    return yt / context.scale
  end
    
  # returns the hexagon number (hn) given the x (xp), y (yp) display coordinates
  # dictionary
  # sl: section line
  # sc: section column
  # xs: x coordinate within section
  # ys: y coordinate within section
  # gr: gradient of half an hexagon triangle
  # hl: hexagon line
  # hc: hexagon column
  def hn_from_xyp(xp, yp)
    sc = (xp / fw).floor
    sl = (yp / (th + hex_side_length)).floor
    xs = xp - sc * fw
    ys = yp - sl * (th + hex_side_length)
    gr = th / rhl
    if sl%2 == 0 then
      # default zone for odd section line
      hl = sl
      hc = sc
      # upper left triangle
      if ys < (th - xs * gr) then
        hl = hl - 1
        hc = hc - 1
      end
      # upper right triangle
      if ys < (- th + xs * gr) then
        hl = hl - 1
      end
    else
      # even section line
      if xs >= rhl then
        # right side
        if ys < (2 * th - xs * gr) then
          # upper triangle
          hl = sl - 1
          hc = sc
        else  
          # lower polygon 
          hl = sl
          hc = sc
        end
      else    
        # left side
        if ys < (xs * gr) then
          # upper triangle
          hl = sl - 1
          hc = sc
        else
          # lower polygon
          hl = sl
          hc = sc - 1
        end    
      end
    end
    # adjust for off grid situations
    if hl < 0 or hl >= maxlin or hc < 0 or hc >= (maxcol - hl%2)  then
      return -1
    else  
      return hn_from_hcl(hc, hl)
    end  
  end

  # returns the x (xp) display coordinate given the hexagon number (hn)
  # dictionary
  # - fw: hexagon (f)ull (w)idth
  # - rhl: hexagon (r)ectangle (h)alf (l)ength
  def xp_from_hn(hn)
    return hc_from_hn(hn) * fw + hl_from_hn(hn)%2 * rhl
  end

  # returns the y (yp) display coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  # - hex_side_length
  def yp_from_hn(hn)
    return hl_from_hn(hn) * (th + hex_side_length)
  end

# CANDIDAT A UN TRASFERT DANS LA CLASSE hEXAGONE
  # returns the x display coordinate of a given vertex of the given hexagon
  def x_vertex(hexagon, vertex)
    x = case vertex
      when "N"  then x_north(hexagon)
      when "NE" then x_north_east(hexagon)
      when "SE" then x_south_east(hexagon)
      when "S"  then x_south(hexagon)
      when "SO" then x_south_west(hexagon)
      when "NO" then x_north_west(hexagon)
    end
    return x.floor   
  end

  # returns the y display coordinate of a given vertex of the given hexagon
  def y_vertex(hexagon, vertex)
    y = case vertex
      when "N"  then y_north(hexagon)
      when "NE" then y_north_east(hexagon)
      when "SE" then y_south_east(hexagon)
      when "S"  then y_south(hexagon)
      when "SO" then y_south_west(hexagon)
      when "NO" then y_north_west(hexagon)
    end
    return y.floor    
  end

  # returns the x north coordinate given the hexagon number (hn)
  # dictionary
  # - rhl: hexagon (r)ectangle (h)alf (l)ength
  def x_north(hn)
    return xp_from_hn(hn) + rhl 
  end

  # returns the y north coordinate given the hexagon number (hn)
  def y_north(hn)
    return yp_from_hn(hn)
  end

  # returns the x north_east coordinate given the hexagon number (hn)
  # dictionary
  # - fw: hexagon (f)ull (w)idth
  def x_north_east(hn)
    return xp_from_hn(hn) + fw 
  end

  # returns the y north east coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  def y_north_east(hn)
    return yp_from_hn(hn) + th
  end

  # returns the x south_east coordinate given the hexagon number (hn)
  # dictionary
  # - fw: hexagon (f)ull (w)idth
  def x_south_east(hn)
    return xp_from_hn(hn) + fw 
  end

  # returns the y south east coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  # - hex_side_length
  def y_south_east(hn)
    return yp_from_hn(hn) + th + hex_side_length
  end

  # returns the x south coordinate given the hexagon number (hn)
  # dictionary
  # - rhl: hexagon (r)ectangle (h)alf (l)ength
  def x_south(hn)
    return xp_from_hn(hn) + rhl 
  end

  # returns the y north coordinate given the hexagon number (hn)
  # dictionary
  # - fh: hexagon (f)ull (h)eight
  def y_south(hn)
    return yp_from_hn(hn) + fh
  end

  # returns the x north_west coordinate given the hexagon number (hn)
  def x_north_west(hn)
    return xp_from_hn(hn) 
  end

  # returns the y north west coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  def y_north_west(hn)
    return yp_from_hn(hn) + th
  end

  # returns the x south_west coordinate given the hexagon number (hn)
  def x_south_west(hn)
    return xp_from_hn(hn) 
  end

  # returns the y south west coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  # - hex_side_length
  def y_south_west(hn)
    return yp_from_hn(hn) + th + hex_side_length
  end

  # returns the hexagon column (hc) given the hexagon number (hn)
  def hc_from_hn(hn)
    r = hn%(maxcol * 2 - 1)
    return r%maxcol
  end

  # returns the hexagon line (hl) given the hexagon number (hn)
  def hl_from_hn(hn)
    g = (hn / (maxcol * 2 - 1)).floor * 2
    r = hn%(maxcol * 2 - 1)
    (r >= maxcol) ? g + 1 : g
  end

  # returns the hexagon number (hn) given the hexagon column (hc) and line (hl)
  def hn_from_hcl(hc, hl)
    return (hl / 2).floor * (maxcol * 2 - 1) + hc + hl%2 * maxcol 
  end

  # th: hexagon triangle height
  def th
    return ((hex_side_length - 0.30) * Math.sin(Math::PI / 6))
  end

  # rhl: hexagon rectangle half length
  def rhl
    return ((hex_side_length - 0.15) * Math.cos(Math::PI / 6)) 
  end   

  # - fh: hexagon full height
  def fh
    return hex_side_length + 2 * th
  end

  # - fw: hexagon full width 
  def fw
    return 2 * rhl
  end  

end
