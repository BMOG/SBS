module Grid

  @hs = Hash.from_xml(Scenario.find(5).definition)  
  @maxcol = Integer(@hs ["scenario"] ["carte"] ["taille_carte"] ["nombre_colonnes"])
  @maxlin = Integer(@hs ["scenario"] ["carte"] ["taille_carte"] ["nombre_lignes"])
  @mapwid = Integer(@hs ["scenario"] ["carte"] ["largeur_image"])
  @maphei = Integer(@hs ["scenario"] ["carte"] ["hauteur_image"])
  
  # returns the central hexagon number of the grid
  def Grid.central_hexagon_number
    return hn_from_hlc((@maxlin / 2).floor, ((@maxcol - 1) / 2).floor)
  end 

  # returns the x translation from the context
  # dictionary
  # xcch: x coordinate of the canvas central hexagon
  # amw: adjusted map width
  def Grid.x_translation(context)
    xcch = (context.cw / 2).floor - (@parameter.rhl * context.scale).floor
    amw = (@mapwid * context.scale).floor
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
  def Grid.y_translation(context)
    ycch = (context.ch / 2).floor - ((@parameter.th + @parameter.rhl / 2) * context.scale).floor
    amh = (@maphei * context.scale).floor
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
  def Grid.hn_from_xyp(xp, yp)
#Rails.logger.debug "hn_from_xyp: (#{xp}, #{yp})"
    sc = (xp / @parameter.fw).floor
#Rails.logger.debug "sc: #{sc}"
    sl = (yp / (@parameter.th + @parameter.hsl)).floor
#Rails.logger.debug "sl: #{sl}"
    xs = xp - sc * @parameter.fw
#Rails.logger.debug "xs: #{xs}"
    ys = yp - sl * (@parameter.th + @parameter.hsl)
#Rails.logger.debug "ys: #{ys}"
    gr = @parameter.th / @parameter.rhl
#Rails.logger.debug "gr: #{gr}"
    if sl.modulo(2) == 0 then
#Rails.logger.debug "odd section line"
      # default zone for odd section line
      hl = sl
#Rails.logger.debug "hl default: #{hl}"
      hc = sc
#Rails.logger.debug "hc default: #{hc}"
      # upper left triangle
      if ys < (@parameter.th - xs * gr) then
#Rails.logger.debug "upper left triangle"
        hl = hl - 1
#Rails.logger.debug "hl correction: #{hl}"
        hc = hc - 1
#Rails.logger.debug "hc correction: #{hc}"
      end
      # upper right triangle
      if ys < (- @parameter.th + xs * gr) then
#Rails.logger.debug "upper right traingle"
        hl = hl - 1
#Rails.logger.debug "hl correction: #{hl}"
      end
    else
      # even section line
#Rails.logger.debug "even section line"
      if xs >= @parameter.rhl then
#Rails.logger.debug "right side"
        # right side
        if ys < (2 * @parameter.th - xs * gr) then
#Rails.logger.debug "right side, upper triangle"
          # upper triangle
          hl = sl - 1
#Rails.logger.debug "hl: #{hl}"
          hc = sc
#Rails.logger.debug "hc: #{hc}"
        else  
          # lower polygon 
#Rails.logger.debug "right side, lower polygon"
          hl = sl
#Rails.logger.debug "hl: #{hl}"
          hc = sc
#Rails.logger.debug "hc: #{hc}"
        end
      else    
        # left side
#Rails.logger.debug "left side"
        if ys < (xs * gr) then
          # upper triangle
#Rails.logger.debug "left side, upper triangle"
          hl = sl - 1
#Rails.logger.debug "hl: #{hl}"
          hc = sc
#Rails.logger.debug "hc: #{hc}"
        else
          # lower polygon
#Rails.logger.debug "left side, lower polygon"
          hl = sl
#Rails.logger.debug "hl: #{hl}"
          hc = sc - 1
#Rails.logger.debug "hc: #{hc}"
        end    
      end
    end
    # adjust for off grid situations
    if hl < 0 or hl >= @maxlin or hc < 0 or hc >= (@maxcol - hl%2)  then
#Rails.logger.debug "return: -1"
      return -1
    else  
#Rails.logger.debug "return hn_from_xyp(#{hl}, #{hc}): #{hn_from_hlc(hl, hc)}"
      return hn_from_hlc(hl, hc)
    end  
  end

  # returns the x (xp) display coordinate given the hexagon number (hn)
  # dictionary
  # - fw: hexagon (f)ull (w)idth
  # - rhl: hexagon (r)ectangle (h)alf (l)ength
  def Grid.xp_from_hn(hn)
    return hc_from_hn(hn) * @parameter.fw + hl_from_hn(hn).modulo(2) * @parameter.rhl
  end

  # returns the y (yp) display coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  # - hsl: (h)exagon (s)ide (l)ength
  def Grid.yp_from_hn(hn)
    return hl_from_hn(hn) * (@parameter.th + @parameter.hsl)
  end

  # returns the x north coordinate given the hexagon number (hn)
  # dictionary
  # - rhl: hexagon (r)ectangle (h)alf (l)ength
  def Grid.x_north(hn)
    return xp_from_hn(hn) + @parameter.rhl 
  end

  # returns the y north coordinate given the hexagon number (hn)
  def Grid.y_north(hn)
    return yp_from_hn(hn)
  end

  # returns the x north_east coordinate given the hexagon number (hn)
  # dictionary
  # - fw: hexagon (f)ull (w)idth
  def Grid.x_north_east(hn)
    return xp_from_hn(hn) + @parameter.fw 
  end

  # returns the y north east coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  def Grid.y_north_east(hn)
    return yp_from_hn(hn) + @parameter.th
  end

  # returns the x south_east coordinate given the hexagon number (hn)
  # dictionary
  # - fw: hexagon (f)ull (w)idth
  def Grid.x_south_east(hn)
    return xp_from_hn(hn) + @parameter.fw 
  end

  # returns the y south east coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  # - hsl: (h)exagon (s)ide (l)ength
  def Grid.y_south_east(hn)
    return yp_from_hn(hn) + @parameter.th + @parameter.hsl
  end

  # returns the x south coordinate given the hexagon number (hn)
  # dictionary
  # - rhl: hexagon (r)ectangle (h)alf (l)ength
  def Grid.x_south(hn)
    return xp_from_hn(hn) + @parameter.rhl 
  end

  # returns the y north coordinate given the hexagon number (hn)
  # dictionary
  # - fh: hexagon (f)ull (h)eight
  def Grid.y_south(hn)
    return yp_from_hn(hn) + @parameter.fh
  end

  # returns the x north_west coordinate given the hexagon number (hn)
  def Grid.x_north_west(hn)
    return xp_from_hn(hn) 
  end

  # returns the y north west coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  def Grid.y_north_west(hn)
    return yp_from_hn(hn) + @parameter.th
  end

  # returns the x south_west coordinate given the hexagon number (hn)
  def Grid.x_south_west(hn)
    return xp_from_hn(hn) 
  end

  # returns the y south west coordinate given the hexagon number (hn)
  # dictionary
  # - th: hexagon (t)riangle (h)eight
  # - hsl: (h)exagon (s)ide (l)ength
  def Grid.y_south_west(hn)
    return yp_from_hn(hn) + @parameter.th + @parameter.hsl
  end

  # returns the hexagon column (hc) given the hexagon number (hn)
  def Grid.hc_from_hn(hn)
    r = hn.modulo(@maxcol * 2 - 1)
    return r.modulo(@maxcol)
  end

  # returns the hexagon line (hl) given the hexagon number (hn)
  def Grid.hl_from_hn(hn)
    g = (hn / (@maxcol * 2 - 1)).floor * 2
    r = hn.modulo(@maxcol * 2 - 1)
    (r >= @maxcol) ? g + 1 : g
  end

  # returns the hexagon number (hn) given the hexagon line (hl) and column (hc)
  def Grid.hn_from_hlc(hl, hc)
    return (hl / 2).floor * (@maxcol * 2 - 1) + hc + hl.modulo(2) * @maxcol 
  end

end 
