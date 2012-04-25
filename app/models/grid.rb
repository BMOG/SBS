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

  # returns the central hexagon number of the grid
  def central_hexagon_number
    return hn_from_hlc((maxlin / 2).floor, ((maxcol - 1) / 2).floor)
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
#Rails.logger.debug "hn_from_xyp: (#{xp}, #{yp})"
    sc = (xp / fw).floor
#Rails.logger.debug "sc: #{sc}"
    sl = (yp / (th + hex_side_length)).floor
#Rails.logger.debug "sl: #{sl}"
    xs = xp - sc * fw
#Rails.logger.debug "xs: #{xs}"
    ys = yp - sl * (th + hex_side_length)
#Rails.logger.debug "ys: #{ys}"
    gr = th / rhl
#Rails.logger.debug "gr: #{gr}"
    if sl%2 == 0 then
#Rails.logger.debug "odd section line"
      # default zone for odd section line
      hl = sl
#Rails.logger.debug "hl default: #{hl}"
      hc = sc
#Rails.logger.debug "hc default: #{hc}"
      # upper left triangle
      if ys < (th - xs * gr) then
#Rails.logger.debug "upper left triangle"
        hl = hl - 1
#Rails.logger.debug "hl correction: #{hl}"
        hc = hc - 1
#Rails.logger.debug "hc correction: #{hc}"
      end
      # upper right triangle
      if ys < (- th + xs * gr) then
#Rails.logger.debug "upper right traingle"
        hl = hl - 1
#Rails.logger.debug "hl correction: #{hl}"
      end
    else
      # even section line
#Rails.logger.debug "even section line"
      if xs >= rhl then
#Rails.logger.debug "right side"
        # right side
        if ys < (2 * th - xs * gr) then
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
    if hl < 0 or hl >= maxlin or hc < 0 or hc >= (maxcol - hl%2)  then
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

  # returns the hexagon number (hn) given the hexagon line (hl) and column (hc)
  def hn_from_hlc(hl, hc)
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
