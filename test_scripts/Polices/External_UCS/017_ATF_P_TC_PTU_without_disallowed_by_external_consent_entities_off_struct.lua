---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] External UCS: PTU without "disallowed_by_external_consent_entities_off struct
--
-- Description:
-- In case:
-- SDL receives PolicyTableUpdate without “disallowed_by_external_consent_entities_off:
-- [entityType: <Integer>, entityId: <Integer>]” -> of "<functional grouping>"
-- -> from "functional_groupings" section
-- SDL must:
-- a. consider this PTU as valid (with the pre-conditions of all other valid PTU content)
-- b. do not create this "disallowed_by_external_consent_entities_off" field
-- of the corresponding "<functional grouping>" in the Policies database.
--
-- Preconditions:
-- 1. Start SDL (make sure 'disallowed_by_external_consent_entities_off' section is omitted in PreloadedPT)
--
-- Steps:
-- 1. Register app1
-- 2. Activate app1
-- 3. Perform PTU
-- 4. Verify status of update
-- 5. Register app2
-- 6. Activate app2
-- 7. Verify PTSnapshot
--
-- Expected result:
-- a. PTU finished successfully with UP_TO_DATE status
-- b. Section "disallowed_by_external_consent_entities_off" is omitted
--
-- Note: Script is designed for EXTERNAL_PROPRIETARY flow
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForExternalUCS = require('user_modules/shared_testcases/testCasesForExternalUCS')

--[[ Local variables ]]
local checkedStatus = "UP_TO_DATE"
local checkedSection = "disallowed_by_external_consent_entities_off"
local grpId = "Location-1"

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForExternalUCS.removePTS()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  testCasesForExternalUCS.startSession(self, 1)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RAI_1()
  testCasesForExternalUCS.registerApp(self, 1)
end

function Test:ActivateApp_1()
  testCasesForExternalUCS.activateApp(self, 1, checkedStatus)
end

function Test:CheckStatus_UP_TO_DATE()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, { status = checkedStatus })
end

function Test.RemovePTS()
  testCasesForExternalUCS.removePTS()
end

function Test:StartSession()
  testCasesForExternalUCS.startSession(self, 2)
end

function Test:RAI_2()
  testCasesForExternalUCS.registerApp(self, 2)
end

function Test:ActivateApp_2()
  testCasesForExternalUCS.activateApp(self, 2)
end

function Test:CheckPTS()
  if not testCasesForExternalUCS.pts then
    self:FailTestCase("PTS was not created")
  else
    if testCasesForExternalUCS.pts.policy_table.functional_groupings[grpId][checkedSection] ~= nil then
      self:FailTestCase("Section '" .. checkedSection .. "' was found in PTS")
    else
      print("Section '".. checkedSection .. "' doesn't exist in PTS")
      print(" => OK")
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.StopSDL()
  StopSDL()
end

return Test
