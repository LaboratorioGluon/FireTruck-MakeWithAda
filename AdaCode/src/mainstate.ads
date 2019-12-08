
package MainState is

   type State is (OFF,
                  STARTING,
                  MOVING,
                  IN_RANGE,
                  ENDING);
   
   currentState : State := OFF;
   
end MainState;
