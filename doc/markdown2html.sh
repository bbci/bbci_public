#!/bin/sh
# converts all toolbox.markdown files into corresponding .html files
# 9/12 hendrik purwins

FNAMES="ToolBox ToolboxIntro ToolboxAutomation ToolboxOnline ToolboxPracticalExamples ToolboxSetup ToolboxData ToolboxStatisticalAnova ToolboxExperimentalStudy ToolboxStatisticsNonparametric ToolboxFileio ToolboxStatisticsTtest ToolboxOnlineForEndUsers ToolboxOnlineTutorial ToolboxOnlineBbciApplyIntroduction ToolboxOnlineBbciApplyStructure ToolboxOnlineBbciImplementingAcquisition ToolboxOnlineBbciImplementingCalibration ToolboxOnlineBbciExampleSuperSpeller ToolboxRequirements"

for FNAME in $FNAMES; do
 cmd="pandoc    -f markdown -t html    "$FNAME.markdown"   -o   "$FNAME.html"" 
 echo $cmd
 eval $cmd
done