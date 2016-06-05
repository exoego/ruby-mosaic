require 'rmagick'

include Magick

#　この長さ（px）の平方（20なら20px x 20px）の領域ごとに色の平均を出し、モザイク１タイルの色とする
TILE_SIZE = 20
# 長辺のモザイクタイルの個数
TILE_PER_SIDE = 15
# 出力画像の長辺の長さ（px）
OUTPUT_LENGTH_IN_PX = TILE_SIZE * TILE_PER_SIDE * 2


def main(img_path, out_dir, out_ext = 'png', mosaic_per_row = TILE_PER_SIDE)
  # ファイル名の拡張子除いた部分
  filename = img_path.gsub(/.+\/([^\/]+)$/) { $1 }.gsub(/\.[^.]+/, '')

  img = ImageList.new(img_path)

  # 速度を稼ぐために、画像サイズを小さくする
  if img.columns > img.rows
    width, height = resize_dimension(img.columns, img.rows, mosaic_per_row)
  else
    height, width = resize_dimension(img.rows, img.columns, mosaic_per_row)
  end
  img.resize_to_fill!(width, height)

  mozaic!(img, TILE_SIZE)
  img.resize_to_fit!(OUTPUT_LENGTH_IN_PX, OUTPUT_LENGTH_IN_PX)
  img.write "#{out_dir}/#{filename}.#{out_ext}"
end


def resize_dimension(longer, shorter, tile_per_side)
  if shorter > longer
    raise 'shorter is longer'
  end
  resize_longer = TILE_SIZE * tile_per_side
  # 正方形モザイクだけで埋めつくせるように、正方形のｎ倍に収まらず長方形になってしまう余りを切り捨てる
  resize_shorter = trim_leftover(resize_longer * shorter / longer, TILE_SIZE)
  [resize_longer, resize_shorter]
end


def trim_leftover (length, unit)
  len = length.ceil
  leftover = len % unit
  len - leftover
end


def mozaic!(img, tile_per_side)
  px = (img.columns / tile_per_side).ceil
  py = (img.rows / tile_per_side).ceil

  product((0...py + 1).collect { |y| y * tile_per_side },
          (0...px + 1).collect { |x| x * tile_per_side }).collect { |ty, tx|
    tiles = product((0...tile_per_side).collect { |iy| iy + ty },
                    (0...tile_per_side).collect { |ix| ix + tx })

    red = NumberAccumulator.new
    green = NumberAccumulator.new
    blue = NumberAccumulator.new
    tiles.collect { |iy, ix|
      pixel = img.pixel_color(ix, iy)
      red.add(pixel.red)
      green.add(pixel.green)
      blue.add(pixel.blue)
    }
    tile_color = Magick::Pixel.new(red.average(), green.average(), blue.average())

    tiles.collect { |iy, ix|
      img.pixel_color(ix, iy, tile_color)
    }
  }
end


def product(range1, range2)
  range1.to_a.product(range2.to_a)
end


class NumberAccumulator
  def initialize
    @total = 0
    @count = 0
  end

  def add(item)
    @total += item
    @count += 1
  end

  def average
    @total / @count
  end
end


Dir.glob('images/*') { |img_path|
  main(img_path, 'mosaic')
}