require File.expand_path(File.dirname(__FILE__) + "/star.rb")
require File.expand_path(File.dirname(__FILE__) + "/box.rb")

class Galaxy
  attr_accessor :stars, :box

  def initialize(size, stars_count, gravity_constant, force_change_distance, stars_distribution, barnes_hut_ratio)
    @size_x = size
    @size_y = size
    @gravity_constant = gravity_constant
    @force_change_distance = force_change_distance
    @barnes_hut_ratio = barnes_hut_ratio

    @stars = []
    
    stars_count.times do |i|
      @stars << Star.generate_random(@size_x, @size_y, stars_distribution)
    end
  end

  def distance_between(body_1, star_2)
    Math.sqrt((body_1.x - star_2.x) ** 2 + (body_1.y - star_2.y) ** 2)
  end

  def force_between(star_1, star_2, distance)
    1.0 * @gravity_constant * star_1.mass * star_2.mass / [distance, @force_change_distance].max
  end

  def update_forces_between(star_1, star_2)
    distance = distance_between(star_1, star_2)
    force = force_between(star_1, star_2, distance)
    force_x = force * (star_1.x - star_2.x) / distance
    force_y = force * (star_1.y - star_2.y) / distance
    star_1.update_acceleration(-force_x, -force_y)
    star_2.update_acceleration(force_x, force_y)
  end

  def calculate_forces(algorithm)
    case algorithm
    when :standard
      standard_move
    when :barnes_hut
      barnes_hut_move
    end
  end

  def standard_move
    #n**2 

    each_stars_pair do |s1, s2|
      update_forces_between(s1, s2)
    end
  end

  def barnes_hut_move
    # n * log(n)
    @box = Box.from_galaxy(self)

    stars.each do |star|
      update_box_forces_between(box, star)
    end
  end

  def update_box_forces_between(box, star)
    if box.width / distance_between(box, star) < @barnes_hut_ratio
      count_actual_force_between(box, star)
    else
      update_box_forces_between(box.top_left_child, star) if box.top_left_child
      update_box_forces_between(box.top_right_child, star) if box.top_right_child
      update_box_forces_between(box.bottom_left_child, star) if box.bottom_left_child
      update_box_forces_between(box.bottom_right_child, star) if box.bottom_right_child
    end 
  end

  def count_actual_force_between(box, star)
    distance = distance_between(box, star)
    force = force_between(box, star, distance) / distance
    force_x = force * (box.x - star.x)
    force_y = force * (box.y - star.y)
    star.update_acceleration(force_x, force_y)
  end

  def move_stars
    stars.map(&:move)
  end

  def join_stars_that_are_closer_than(joining_distance)
    each_stars_pair do |s1, s2|
      if distance_between(s1, s2) < joining_distance
        stars << s1 + s2
        stars.delete(s1)
        stars.delete(s2)
        break
      end
    end
  end

  def each_stars_pair
    (0...stars.length).each do |i|
      ((i+1)...stars.length).each do |j|
        yield stars[i], stars[j]
      end
    end
  end
end