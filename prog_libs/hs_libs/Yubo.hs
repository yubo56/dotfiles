module Yubo where

import Control.Lens
import Data.Colour
import Data.Colour.Names
import Data.Default.Class
import Graphics.Histogram
import qualified Graphics.Gnuplot.Frame.OptionSet as Opts
import qualified Graphics.Gnuplot.Frame.OptionSet.Histogram as Histogram
import Graphics.Rendering.Chart
import Graphics.Rendering.Chart.Backend.Cairo
import Text.Printf

-------------------------------------------------------------------------------
---------------------------------- UTILS --------------------------------------
-------------------------------------------------------------------------------

addArr :: Num a => [a] -> [a] -> [a]
addArr = zipWith (+)

-------------------------------------------------------------------------------
--------------------------------- PLOTTING ------------------------------------
-------------------------------------------------------------------------------

size = 20

{-
  yuboBar
    [("Dat", blue), ("foo", red)]
    [("Boys", [1, 3]), ("Girls", [2, 4])]
    "title"
    "/tmp/barchart.png"
-}
yuboBar ::
  [(String, Colour Double)] ->
  [(String, [Int])] ->
  String ->
  String ->
  IO (PickFn ())
yuboBar cols dat title fn = renderableToFile def fn renderable
  where
    x_axis_labels = map fst dat
    y_axis_values = map snd dat
    titles = map fst cols
    colours = map snd cols

    barChart =
        plot_bars_titles  .~ titles $
        plot_bars_values  .~ addIndexes y_axis_values $
        plot_bars_item_styles .~
          [(solidFillStyle (opaque c), Nothing) | c <- colours] $
        def

    layout =
        layout_title .~ title $
        layout_x_axis . laxis_generate .~ autoIndexAxis x_axis_labels $
        layout_left_axis_visibility . axis_show_ticks .~ False $
        layout_plots .~ [plotBars barChart] $
        def :: Layout PlotIndex Int

    renderable = toRenderable layout

{-
  yuboLine [(blue, "line", [0, 2], [1, 3])] "x" "y" "t" "/tmp/a.png"
-}
yuboLine ::
  [(Colour Double, String, [Float], [Float])] ->
  String ->
  String ->
  String ->
  String ->
  IO(PickFn ())
yuboLine dat xlabel ylabel title fn = renderableToFile def fn renderable
  where
    plotline (colour, lineTitle, x, y) =
      plot_lines_style .~ solidLine 3.0 (opaque colour) $
      plot_lines_values .~ [zip x y] $
      plot_lines_title .~ lineTitle $
      def

    layout =
      layout_title .~ title $
      layout_title_style . font_size .~ size $
      layout_x_axis . laxis_override .~ axisGridHide $
      layout_x_axis . laxis_title .~ xlabel $
      layout_x_axis . laxis_style . axis_label_style . font_size .~ size $
      layout_x_axis . laxis_title_style . font_size .~ size $
      layout_y_axis . laxis_title .~ ylabel $
      layout_y_axis . laxis_style . axis_label_style . font_size .~ size $
      layout_y_axis . laxis_title_style . font_size .~ size $
      layout_plots .~ map (toPlot . plotline) dat $
      layout_grid_last .~ False $
      def

    renderable = toRenderable layout
{-
  yuboScat [(blue, "line", [(1, 2), (3, 4)])] "x" "y" "t" "/tmp/a.png"
-}
yuboScat ::
  [(Colour Double, String, [(Float, Float)])] ->
  String ->
  String ->
  String ->
  String ->
  IO(PickFn ())
yuboScat dat xlabel ylabel title fn = renderableToFile def fn renderable
  where
    plotline (colour, lineTitle, pts) =
      plot_points_style .~ filledCircles 0.5 (opaque colour) $
      plot_points_values .~ pts $
      plot_points_title .~ lineTitle $
      def

    layout =
      layout_title .~ title $
      layout_title_style . font_size .~ size $
      layout_x_axis . laxis_override .~ axisGridHide $
      layout_x_axis . laxis_title .~ xlabel $
      layout_x_axis . laxis_style . axis_label_style . font_size .~ size $
      layout_x_axis . laxis_title_style . font_size .~ size $
      layout_y_axis . laxis_title .~ ylabel $
      layout_y_axis . laxis_style . axis_label_style . font_size .~ size $
      layout_y_axis . laxis_title_style . font_size .~ size $
      layout_plots .~ map (toPlot . plotline) dat $
      layout_grid_last .~ False $
      def

    renderable = toRenderable layout


{-
  yuboHist [sin x | x <- [0..9999]] "title" "xlabel" "ylabel" "/tmp/foo.png"
-}
data Histogram = Histogram Double Double [(Double,Int)]

_nSturges :: [Double] -> Int
_nSturges xs = ceiling $ logBase 2 n + 1
  where n = fromIntegral $ length xs
_nSqrt :: [Double] -> Int
_nSqrt = ceiling . sqrt . fromIntegral . length

yuboHist ::
  ([Double] -> Int) ->
  [Double] ->
  String ->
  String ->
  String ->
  String ->
  IO ()
yuboHist f dat xlabel ylabel title fn = do
  print tickLocs
  plotAdv fn opts hist
  return ()
    where
      numTicks = 5

      mindat = minimum dat
      maxdat = maximum dat
      binsize = (maxdat - mindat) / max (fromIntegral (f dat)) 1
      roundedsize = fromIntegral (round (binsize * 1000)) / 1000
      nbins = ceiling $ (maxdat - mindat) / roundedsize

      hist = histogramBinSize roundedsize dat
      baseTickLabels = zip (replicate (nbins + 1) "") [0..]
      tickLocs = [round (y * fromIntegral nbins / numTicks) | y <- [0..numTicks]]
      tickLabels = map
        (\(s, idx) -> if idx `elem` tickLocs; then
          (printf "%.2f" ((fromIntegral idx * roundedsize) + mindat), idx) else
          (s, idx))
        baseTickLabels
      opts =
        Opts.title title $
        Opts.yLabel xlabel $
        Opts.xLabel ylabel $
        Opts.xTicks2d tickLabels $
        defOpts hist

yuboHistSturges :: [Double] -> String -> String -> String -> String -> IO ()
yuboHistSturges = yuboHist _nSturges
yuboHistSqrt :: [Double] -> String -> String -> String -> String -> IO ()
yuboHistSqrt = yuboHist _nSqrt
