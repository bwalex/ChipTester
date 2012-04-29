$base_freq = 100;
$cmax = 255;

$fvco = []
$bins = []

for i in (500..1200).step(20)
  f = { :f => i, :m => i/20, :n => 5 }

  #puts "F_vco: #{f[:f]}, m: #{f[:m]}, n: #{f[:n]}"
  $fvco << f
end


for i in 1..$cmax
  c = i * 2
  $fvco.each do |f_vco|
    f = f_vco[:f].to_f / c.to_f
    f_int = f.round
    f_err = (f_int - f).abs
    $bins[f_int] = { :err => f_err, :m => f_vco[:m], :n => f_vco[:n], :c => i}  if $bins[f_int].nil?   or f_err < $bins[f_int][:err]
    f_err = (f_int-1 - f).abs
    $bins[f_int-1] = { :err => f_err, :m => f_vco[:m], :n => f_vco[:n], :c => i} if $bins[f_int-1].nil? or f_err < $bins[f_int-1][:err]
    f_err = (f_int+1 - f).abs
    $bins[f_int+1] = { :err => f_err, :m => f_vco[:m], :n => f_vco[:n], :c => i} if $bins[f_int+1].nil? or f_err < $bins[f_int+1][:err]
  end
end

puts "static
struct pll_settings {
\tuint8_t m;
\tuint8_t n;
\tuint8_t c;
} pll_settings[] = {
\t{ .m = 6,\t.n = 1,\t.c = 30 },
";

for i in 1..100
  b = $bins[i]
  if not b.nil?
    #puts "f: #{i}, e: #{b[:err]}, m: #{b[:m]}, n: #{b[:n]}, c: #{b[:c]}"
    puts "\t{ .m = #{b[:m]},\t.n = #{b[:n]},\t.c = #{b[:c]} },\t/* #{i} MHz, err: #{b[:err]} */"
  else
    puts "HOLE at f: #{i}"
  end
end

puts '};'
