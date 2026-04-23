class Encounter
  RATE = 1.0 / 8

  def self.check?
    rand < RATE
  end

  # Generate a group of monsters for the given area (1–3 of same species).
  def self.generate_group(area_key)
    normal = Monster.data[area_key]['normal']
    base   = normal.sample
    count  = case rand
             when 0..0.55 then 1
             when 0.55..0.82 then 2
             else 3
             end
    count.times.map { Monster.new(base) }
  end
end
