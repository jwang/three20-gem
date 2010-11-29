Feature: Install Three20
  In order to use three20
  A user must install three20 first
  user runs three20 install from command line.

  Scenario: Install
    Given gem is installed
    When I run three20 install
    Then I should see installing three20
