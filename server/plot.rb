require 'rubygems'
require 'gnuplot'

x = []
y = []

def plot_png(filename, output_filename, n_samples = 4000, x_scale = 0.01, y_scale = 1.024/0.295/256)
  y = []

  File.open(filename, "rb:binary") do |f|
    bytes = f.read
    y = bytes.unpack("C*") # uppercase C is unsigned, lowercase is signed
  end

  y = y[0..n_samples].collect { |v| y_scale * v.to_f }
  x = (0..n_samples).collect { |v| v.to_f * x_scale }

  Gnuplot.open do |gp|
    Gnuplot::Plot.new( gp ) do |plot|
  
      plot.title  "ADC capture"
      plot.ylabel "A / V"
      plot.xlabel "t / us"
      plot.yrange "[0:3.5]"
      plot.xrange "[0:#{x.max}]"
      plot.terminal "png size 1400,900"
      plot.output output_filename
    
      plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
        ds.with = "lines"
        ds.notitle
      end
    end
  end
end
