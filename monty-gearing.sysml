
package rock{

 private import ScalarValues::Real;
 private import USCustomaryUnits::inch;
 private import TrigFunctions::pi;
 private import SI::S;
 private import SI::'second to the power minus 1';
 private import SI::minute;
 private import SI::second;

 part def TransmissionStage{
   
   part inputGear : Gear{
    attribute :>> toothCount;
   }
   part outputGear : Gear{
    attribute :>> toothCount;
   }
   attribute gearRatio : Real = outputGear.toothCount/inputGear.toothCount;
 }
 part def Gear{
    attribute toothCount;
 }
 part def AxleAssembly  {
  attribute overallRatio : Real = transmission.transmissionRatio * portaKnuckle.transmissionStage.gearRatio;
  part housing;
  part transmission{
   part firstTransmissionStage : TransmissionStage{
    attribute :>> inputGear.toothCount = 12;
    attribute :>> outputGear.toothCount = 42;
   }
   part secondTransmissionStage : TransmissionStage{
    attribute :>> inputGear.toothCount = 12;
    attribute :>> outputGear.toothCount = 42;
   }
   attribute transmissionRatio :Real  = firstTransmissionStage.gearRatio*secondTransmissionStage.gearRatio;
  }
  
  part portaKnuckle{
   attribute side;
   part transmissionStage : TransmissionStage{
    attribute :>> inputGear.toothCount = 20;
    attribute :>> outputGear.toothCount = 40;
   }
  }
  part leftportaKnuckle :> portaKnuckle{
   attribute :>> side = "driver";
  }
  part rightportaKnuckle :> portaKnuckle{
   attribute :>> side = "driver";
  }
  
  
  ref part wheels [2] : Wheel;
  part motor [1]{
   attribute maxRPM : ISQSpaceTime::AngularFrequencyValue = (30000/60) [second^-1];
  }
 }

part def Wheel {
   attribute diameter : ISQ::LengthValue;
   attribute pi : Real = 3.14159;
   attribute circumference : Real = diameter * pi;
  }

part def Crawler {
    part frontAxel : AxleAssembly {
        part redefines wheels :> Crawler::wheels;
    }
    part rearAxel : AxleAssembly {
        part redefines wheels :> Crawler::wheels;
    }
    part wheels [4] : Wheel {
        attribute redefines diameter : ISQ::LengthValue = 4.75 [inch];
    }
    attribute axleSpeed : Real = frontAxel.motor.maxRPM / frontAxel.overallRatio * wheels.circumference;
}
}

package requirements{
 private import USCustomaryUnits::mph;
 private import rock::AxleAssembly::**;
 private import ScalarValues::Real;
 private import rock::Crawler;
 requirement <'REQ-SPD-001'> speedLimits {
  doc /*The vehicle shall be between 10 mph and 20 mph "*/
  subject crawlerSubject : Crawler;
  
  attribute minSpeed : ISQ::SpeedValue = 10 [mph];
  attribute maxSpeed : ISQ::SpeedValue = 20 [mph];

  assert constraint vehicleSpeed{
   crawlerSubject.axleSpeed > minSpeed and crawlerSubject.axleSpeed < maxSpeed
  }
 }
 requirement <'REQ-SPD-002'> gearRatioLimit{
  doc /*The vehicle shall have a gear ratio between 60 and 100"*/
  subject axleAssemblySubject : AxleAssembly;
  
  attribute minGearRatio : Real = 20;
  attribute maxGearRatio : Real = 100 ;
  
  assert constraint vehicleSpeed{
   axleAssemblySubject.overallRatio > minGearRatio and axleAssemblySubject.overallRatio < maxGearRatio
  }
 }
}