class GraphController < ApplicationController

  def index
    @graph = open_flash_chart_object(960,300,"/graph/meme_strength")
  end

  def meme_strength
    @meme = Meme.find(params[:id])
    
    related_memes = @meme.related_memes.reverse

    strengths = related_memes.map{ |m| m.strength }
    
    chart = OpenFlashChart.new
    # title = Title.new("Strength")
    # title.set_style( "{font-size: 20px; font-family: Helvetica, 'sans serif'; font-weight: bold; color: #333; text-align: center;}" );
    # chart.set_title(title)

    bar = Bar.new
    bar.set_values(strengths)
    bar.colour = '#D24A31'

    chart.add_element(bar)

    tooltip = Tooltip.new
    tooltip.set_stroke(1)
    tooltip.set_colour("#777777")
    tooltip.set_text_color("#777777")
    bar.set_tooltip("#val#")
    
    y = YAxis.new
    num_points_to_skip_on_y_axis = ((strengths.max+10)/16).ceil
    y.set_range(0,strengths.max+10,num_points_to_skip_on_y_axis)
    chart.set_y_axis(y)

    x_axis_labels = related_memes.map{ |m| m.run.ended_at.strftime('%I%p').gsub(/^0/,'') }
    
    modulus = 2
    case x_axis_labels.size
    when 30..50 
      modulus = 2
    when 51..90
      modulus = 3
    when 91..9999
      modulus = 10
    else
      modulus = 20
    end
    if x_axis_labels.size > 30
      x_axis_labels.each_with_index { |label, c|
        if c%modulus == 0
          x_axis_labels[c] = label
        else
          x_axis_labels[c] = ""
        end
        logger.info "#{c} | #{c%modulus}"
      }
    end
    x_axis_labels[0] = related_memes.first.run.ended_at.strftime('%m/%d       ')
    x_axis_labels[strengths.size-1] = related_memes.last.run.ended_at.strftime('       %m/%d')
    x_axis_labels.each_with_index { |label, c|
      x_axis_labels[c] = XAxisLabel.new(label, '#111111', 10, nil)
    }
    
    x_labels = XAxisLabels.new
    x_labels.set_vertical()
    x_labels.labels = x_axis_labels

    x = XAxis.new
    x.set_labels(x_labels)


    x.set_offset(true)
    x.set_labels(x_axis_labels)
    chart.set_x_axis(x)

    chart.set_bg_colour('#ffffff')
    x.set_grid_colour('#efefef')
    x.set_colour('#777777')
    y.set_grid_colour('#efefef')
    y.set_colour('#777777')
    
    
    render :text => chart.to_s
  end
  
end
