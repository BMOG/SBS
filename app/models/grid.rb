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
  belongs_to :scenario
  has_many :hexagons, dependent: :destroy

  VERTICES = [:n, :ne, :se, :s, :so, :no]
  EDGES = [:ne, :e, :se, :so, :o, :no]

  # returns all the points coordinates (x1,y1 x2,Y2 ...) from a polygon defined as an array of hexagons (the enveloppe) and a synchronized array of valid connections for each hexagon
  def polygons_points(p_polygon)
    # initialization
    points = ""
    i_polygon = 0
    current_hexagon = p_polygon[:enveloppe][0]
    i_connection = p_polygon[:connections][0].index("0")
    initial_vertex = "#{current_hexagon.to_s},#{VERTICES[i_connection].to_s}"
    done = false
    
    until done
      while not done and p_polygon[:connections][i_polygon][i_connection] == "0"
        done = initial_vertex == "#{current_hexagon.to_s},#{VERTICES[i_connection].to_s}" unless points.empty?
        unless done
          vertex = VERTICES[i_connection]
          points << "#{x_vertex(current_hexagon, vertex).floor},#{y_vertex(current_hexagon, vertex).floor} "
          i_connection == 5 ? i_connection = 0 : i_connection += 1
        end
      end
      
      if not done and i_connection < 6 then
        current_hexagon = adjacent(current_hexagon, EDGES[i_connection])
        i_polygon = p_polygon[:enveloppe].index(current_hexagon)
        i_connection -= 2
        i_connection += 6 unless i_connection >= 0
      end  
    end
    
    return points.chop
  end 
  
  # returns an array of polygons defined as an array of hexagons (the enveloppe) and a synchronized array of valid connections for each hexagon, from a list of hexagons
  # WARNING! No leading zeroes in hexagon number  
  def build_polygons_definition(p_hexagons)
    hexagons_source = p_hexagons.split(',')
    polygons = Array.new
    hexagons = Array.new
    hexagons_source.each { |h| hexagons << h.to_i}

    until hexagons.empty?
      polygon = Hash.new
      enveloppe = Array.new
      connections = Array.new
      node_stack = Array.new [hexagons.first]
  
      until node_stack.empty?
        connection_string = ""
        current_node = node_stack.pop
        enveloppe << current_node  
        hexagons.delete(current_node)

        EDGES.each do |direction|
          adjacent_hexagon = adjacent(current_node, direction)

          if adjacent_hexagon == -1 then
            connection_string << "0"
          else  
            if hexagons_source.include?(adjacent_hexagon.to_s) then
              connection_string << "1"
              node_stack << adjacent_hexagon unless node_stack.include?(adjacent_hexagon) or enveloppe.include?(adjacent_hexagon) 
            else
              connection_string << "0"
            end  
          end
        end   
    
        connections << connection_string
      end

      polygon[:enveloppe] = enveloppe
      polygon[:connections] = connections
      polygons << polygon
    end     

    return polygons   
  end  
  
  # returns a string of x,y coordinates drawing a polyline across edges from a xml bloc
  def get_polyline_across_edges(p_hash)
    # initialize with the given hash
    hcl = p_hash ["hexagone_depart"].split(';')
    hexagon = hn_from_hcl(hcl.first.to_i, hcl.last.to_i) 
    directions = Service.uncompressed_directions(p_hash ["liste_directions"])
    # provide the beginning of the polyline
    polyline_points = "#{x_center(hexagon)},#{y_center(hexagon)} "
    # for each direction, find the new hexagon then provide the next set of coordinates
    directions.split(',').each do |direction|
      hexagon = adjacent(hexagon, direction.swapcase.intern) 
      polyline_points << "#{x_center(hexagon)},#{y_center(hexagon)} "
    end
    # and return the string of coordinates
    return polyline_points.chop
  end

  # returns a string of x,y coordinates drawing a polyline along edges from a xml bloc
  def get_polyline_on_edges(p_hash)
    # initialize with the given hash
    hcl = p_hash ["hexagone_depart"].split(';')
    hexagon = hn_from_hcl(hcl.first.to_i, hcl.last.to_i) 
    vertex = p_hash ["angle_depart"]
    directions = Service.uncompressed_directions(p_hash ["liste_directions"])
    # provide the beginning of the polyline
    polyline_points = "#{x_vertex(hexagon, vertex.swapcase.intern)},#{y_vertex(hexagon, vertex.swapcase.intern)} "
    # for each direction, find the new hexagon and vertex, then provide the next set of coordinates
    directions.split(',').each do |direction|
      case direction + vertex
        when "NN", "NONE"   then hexagon = adjacent(hexagon, :ne) 
        when "NENE", "NSE"  then hexagon = adjacent(hexagon, :e) 
        when "NES", "SESE"  then hexagon = adjacent(hexagon, :se) 
        when "SS", "SESO"   then hexagon = adjacent(hexagon, :so) 
        when "SNO", "SOSO"  then hexagon = adjacent(hexagon, :o) 
        when "SON", "NONO"  then hexagon = adjacent(hexagon, :no)
      end   
      vertex = case direction
        when "N"  then "NO"       
        when "NE" then "N"      
        when "SE" then "NE"      
        when "S"  then "SE"      
        when "SO" then "S"      
        when "NO" then "SO"
      end          
      polyline_points << "#{x_vertex(hexagon, vertex.swapcase.intern)},#{y_vertex(hexagon, vertex.swapcase.intern)} "
    end
    # and return the string of coordinates
    return polyline_points.chop
  end

# CANDIDAT A UN TRASFERT DANS LA CLASSE hEXAGONE
  # returns the hexagon (number) adjacent to the given hexagon in the given direction
  # returns -1 if there is no adjacent hexagon in the given direction 
  def adjacent(p_hexagon, p_direction)
    hexcol = hc_from_hn(p_hexagon)
    hexlin = hl_from_hn(p_hexagon)
    case p_direction
      when :ne
        hexcol += 1 if hexlin%2 != 0
        hexlin -= 1
      when :e
        hexcol += 1
      when :se
        hexcol += 1 if hexlin%2 != 0
        hexlin += 1
      when :so
        hexcol -= 1 if hexlin%2 == 0
        hexlin += 1
      when :o
        hexcol -= 1
      when :no
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

  # returns the highest hexagon number of the grid
  def highest_hexagon_number
    return hn_from_hcl(maxcol - 1, maxlin - 1)
  end 

  # returns the x translation from the context
  # dictionary
  # xcch: x coordinate of the canvas central hexagon
  # amw: adjusted map width
  def x_translation(p_context)
    xcch = (p_context.cw / 2).floor - (rhl * p_context.scale).floor
    amw = (picture_width * p_context.scale).floor
    xt = xcch - (xp_from_hn(p_context.current_hex) * p_context.scale).floor
    if amw < p_context.cw then
      xt = (p_context.cw - amw) / 2 
    elsif xt > 0 then
      xt = 0
    elsif (xt + amw) < p_context.cw then
      xt = p_context.cw - amw
    end 
    return xt / p_context.scale
  end

  # returns the y translation from the context
  # dictionary
  # ycch: y coordinate of the canvas central hexagon
  # amh: adjusted map height
  def y_translation(p_context)
    ycch = (p_context.ch / 2).floor - ((th + rhl / 2) * p_context.scale).floor
    amh = (picture_height * p_context.scale).floor
    yt = ycch - (yp_from_hn(p_context.current_hex) * p_context.scale).floor
    if amh < p_context.ch then
      yt = (p_context.ch - amh) / 2
    elsif yt > 0 then
      yt = 0
    elsif (yt + amh) < p_context.ch then
      yt = p_context.ch - amh
    end 
    return yt / p_context.scale
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
  def hn_from_xyp(p_xp, p_yp)
    sc = (p_xp / fw).floor
    sl = (p_yp / (th + hex_side_length)).floor
    xs = p_xp - sc * fw
    ys = p_yp - sl * (th + hex_side_length)
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
  def xp_from_hn(p_hn)
    return hc_from_hn(p_hn) * fw + hl_from_hn(p_hn)%2 * rhl
  end

  # returns the y (yp) display coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  # - hex_side_length
  def yp_from_hn(p_hn)
    return hl_from_hn(p_hn) * (th + hex_side_length)
  end

  # returns the x center coordinate given the hexagon number (hn)
  # dictionary
  # - rhl: hexagon (r)ectangle (h)alf (l)ength
  def x_center(p_hn)
    return xp_from_hn(p_hn) + rhl 
  end

  # returns the y center coordinate given the hexagon number (hn)
  # dictionary
  # - fh: hexagon (f)ull (h)eight
  def y_center(p_hn)
    return yp_from_hn(p_hn) + fh / 2 
  end

  # returns the x vertex coordinate given the hexagon number (hn) and the vertex
  # dictionary
  # - rhl: hexagon (r)ectangle (h)alf (l)ength
  # - fw: hexagon (f)ull (w)idth
  def x_vertex(p_hn, p_v)
    case p_v
      when :n, :s   then return xp_from_hn(p_hn) + rhl
      when :ne, :se then return xp_from_hn(p_hn) + fw 
      else               return xp_from_hn(p_hn) 
    end                
  end
  
  # returns the y vertex coordinate given the hexagon number (hn) and the vertex
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  # - fh: hexagon (f)ull (h)eight
  # - hex_side_length
  def y_vertex(p_hn, p_v)
    case p_v
      when :n       then return yp_from_hn(p_hn)
      when :ne, :no then return yp_from_hn(p_hn) + th
      when :s       then return yp_from_hn(p_hn) + fh
      else               return yp_from_hn(p_hn) + th + hex_side_length 
    end                
  end

  # returns the hexagon column (hc) given the hexagon number (hn)
  def hc_from_hn(p_hn)
    r = p_hn%(maxcol * 2 - 1)
    return r%maxcol
  end

  # returns the hexagon line (hl) given the hexagon number (hn)
  def hl_from_hn(p_hn)
    g = (p_hn / (maxcol * 2 - 1)).floor * 2
    r = p_hn%(maxcol * 2 - 1)
    (r >= maxcol) ? g + 1 : g
  end

  # returns the hexagon number (hn) given the hexagon column (hc) and line (hl)
  def hn_from_hcl(p_hc, p_hl)
    return (p_hl / 2).floor * (maxcol * 2 - 1) + p_hc + p_hl%2 * maxcol 
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
