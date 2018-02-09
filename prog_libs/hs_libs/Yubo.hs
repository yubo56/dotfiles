module Yubo where

import Control.Lens
import Data.Colour
import Data.Colour.Names
import Data.Default.Class
import Graphics.Histogram
import qualified Graphics.Gnuplot.Frame.OptionSet as Opts
import Graphics.Rendering.Chart
import Graphics.Rendering.Chart.Backend.Cairo

-------------------------------------------------------------------------------
--------------------------------- PLOTTING ------------------------------------
-------------------------------------------------------------------------------

{-
  barChart
    [("Dat", blue), ("foo", red)]
    [("Boys", [1, 3]), ("Girls", [2, 4])]
    "title"
    "/tmp/barchart.png"
-}
barChart ::
  [(String, Colour Double)] ->
  [(String, [Int])] ->
  String ->
  String ->
  IO (PickFn ())
barChart cols dat title fn = renderableToFile def fn renderable
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
  lineChart [(blue, "line", [0, 2], [1, 3])] "title" "/tmp/linechart.png"
-}
lineChart ::
  [(Colour Double, String, [Float], [Float])] ->
  String ->
  String ->
  IO(PickFn ())
lineChart dat plot_title fn = renderableToFile def fn renderable
  where
    plotline (colour, title, x, y) =
      plot_lines_style .~ solidLine 3.0 (opaque colour) $
      plot_lines_values .~ [zip x y] $
      plot_lines_title .~ title $
      def

    layout =
      layout_title .~ plot_title $
      layout_x_axis . laxis_override .~ axisGridHide $
      layout_plots .~ map (toPlot . plotline) dat $
      layout_grid_last .~ False $
      def

    renderable = toRenderable layout

{-
  histChart [sin x | x <- [0..9999]] "title" "xlabel" "ylabel" "/tmp/foo.png"
-}
histChart :: [Double] -> String -> String -> String -> String -> IO ()
histChart dat xlabel ylabel title fn = do
  plotAdv fn opts hist
  return ()
    where
      hist = histogram binSturges dat
      opts =
        Opts.title title $
        Opts.yLabel xlabel $
        Opts.xLabel ylabel $
        defOpts hist
