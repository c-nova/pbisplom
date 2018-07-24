/*
 *  Power BI Visualizations
 *
 *  Copyright (c) Microsoft Corporation
 *  All rights reserved.
 *  MIT License
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the ""Software""), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

module powerbi.extensibility.visual.pbisplom05E56D040CD74B6887AE3F160D986C31  {
    "use strict";
    import DataViewObjectsParser = powerbi.extensibility.utils.dataview.DataViewObjectsParser;

   export class VisualSettings extends DataViewObjectsParser {
    public rcv_script: RcvScriptSettings = new RcvScriptSettings();

    public PlotSettingsUpper: PlotSettingsUpper = new PlotSettingsUpper();
    public PlotSettingsLower: PlotSettingsLower = new PlotSettingsLower();
    public PlotSettingsDiag: PlotSettingsDiag = new PlotSettingsDiag();
      }

    export class RcvScriptSettings {
      // undefined
       public provider;     // undefined
       public source;
    }

    export class PlotSettingsUpper {
      public ShowSw: boolean = true;
      public Continuous: string = "points";
      public Combo: string = "box";
      public Discrete: string = "facetbar";
    }

    export class PlotSettingsLower {
      public ShowSw: boolean = true;
      public Continuous: string = "points";
      public Combo: string = "box";
      public Discrete: string = "facetbar";
    }

    export class PlotSettingsDiag {
      public ShowSw: boolean = true;
      public Continuous: string = "densityDiag";
      public Discrete: string = "barDiag";
    }

}
