t = (0..2097152)

t = t.collect { |v| v.to_f * 0.000000001 } # in seconds

kHz = 5000

a = t.collect { |v| Math.cos(v * 2 * Math::PI * 1000 * kHz) }

a = a.collect { |v| ((1+v)*127).to_i }

d = a.pack("C*")

File.open("4.adc", "w") do |f|
  f.syswrite(d)
end
