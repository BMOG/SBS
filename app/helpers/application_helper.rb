module ApplicationHelper

  def logo
    image_tag("logo.png", alt: (t :sbs), class: "round")
  end
  
  # Returns the full title on a per-page basis.
  def full_title(page_title)
    base_title = t :sbs
    if page_title.empty?
      base_title
    else
      "#{base_title} - #{page_title}"
    end
  end

end
