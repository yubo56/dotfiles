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
--------------------------------- PLOTTING ------------------------------------
-------------------------------------------------------------------------------

data Histogram = Histogram Double Double [(Double,Int)]

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
  yuboLine [(blue, "line", [0, 2], [1, 3])] "title" "/tmp/linechart.png"
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
    plotline (colour, title, x, y) =
      plot_lines_style .~ solidLine 3.0 (opaque colour) $
      plot_lines_values .~ [zip x y] $
      plot_lines_title .~ title $
      def

    size = 20
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
_nSturges :: [Double] -> Int
_nSturges xs = ceiling $ logBase 2 n + 1
  where n = fromIntegral $ length xs
_nSqrt :: [Double] -> Int
_nSqrt = ceiling . sqrt . fromIntegral . length

_yuboHist ::
  ([Double] -> Int) ->
  [Double] ->
  String ->
  String ->
  String ->
  String ->
  IO ()
_yuboHist f dat xlabel ylabel title fn = do
  plotAdv fn opts hist
  return ()
    where
      mindat = minimum dat
      maxdat = maximum dat
      binsize = (maxdat - mindat) / max (fromIntegral (f dat)) 1
      roundedsize = fromIntegral (round (binsize * 1000)) / 1000
      nbins = ceiling $ (maxdat - mindat) / roundedsize

      hist = histogramBinSize roundedsize dat
      opts =
        Opts.title title $
        Opts.yLabel xlabel $
        Opts.xLabel ylabel $
        Opts.xTicks2d (zip
          ([printf "%.2f" mindat] ++
            replicate (nbins - 1) "" ++
            [printf "%.2f" maxdat])
          [0..]) $
        defOpts hist

yuboHist :: [Double] -> String -> String -> String -> String -> IO ()
yuboHist = _yuboHist _nSturges
yuboHistSqrt :: [Double] -> String -> String -> String -> String -> IO ()
yuboHistSqrt = _yuboHist _nSqrt
