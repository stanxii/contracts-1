pragma solidity ^0.4.2;

import "./zeppelin/Ownable.sol";
import "./milestones/MilestonesAbstraction.sol";
import "./forecasts/ForecastingAbstraction.sol";

contract DAOAbstraction is Ownable {
  /*
    Project Categories
  */
  enum Categories {
    Software,
    Hardware,
    Service,
    Platform,
    NonProfit
  }

  /*
    Projects Periods
  */
  enum ProjectPeriod {
    Review,
    Forecasting,
    Funding,
    AfterFunding
  }

  bytes32 public id; // id of project
  string public name; // name of project
  bytes32 public infoHash; // information hash of project

  address token; // token contract address

  uint public category; // category of project

  uint public timestamp; // timestamp when project created

  uint public reviewHours; // review period of project
  uint public forecastHours; // forecasting hours

  bool public underCap; // is project under cap and latest milestone is cap
  uint public startTimestamp; // time of DAO start activity

  /*
    Contracts
  */
  MilestonesAbstraction public milestones;
  ForecastingAbstraction public forecasting;

  modifier isStarted(bool _value) {
    if (_value == true) {
      if (startTimestamp == 0) {
        throw;
      }

      _;
    } else {
      if (startTimestamp == 0) {
        _;
      } else {
        throw;
      }
    }
  }

  modifier onlyReview() {
    if (startTimestamp == 0 || (block.timestamp < (startTimestamp + (reviewHours * 1 hours)))) {
      _;
    } else {
      throw;
    }
  }

  modifier onlyForecasting() {
    if (block.timestamp < (startTimestamp + (reviewHours + forecastHours) * 1 hours)) {
      _;
    } else {
      throw;
    }
  }

  modifier checkReviewHours(uint _hours) {
    if (_hours < 1 || _hours > 504) {
      throw;
    }

    _;
  }

  modifier checkForecastHours(uint _hours) {
    if (_hours < 120 || _hours > 720) {
      throw;
    }

    _;
  }

  modifier isReadyForStart() {
    if (forecasting == address(0) || forecastHours == 0) {
      throw;
    }

    _;
  }

  /*
    Update project data
  */
  function update(bytes32 _infoHash, uint _category) onlyOwner() onlyReview();

  /*
    Start DAO process
  */
  function start() onlyOwner() isStarted(false);


  /*
    Forecasts
  */

  /*
    Enable forecasts
  */
  function enableForecasts(uint _hours) onlyOwner() isStarted(false) checkForecastHours(_hours);

  /*
    Add forecast
  */
  function addForecast(uint _amount, bytes32 _message) onlyOwner() isStarted(true) onlyForecasting();

  /*
    Get user forecast
  */
  function getUserForecast(address _user) constant returns (uint _amount, uint _timestamp, bytes32 _message);

  /*
    Get forecast
  */
  function getForecast(uint _index) constant returns (uint _amount, uint _timestamp, bytes32 _message);

  /*
    Get forecasts count
  */
  function getForecastsCount() constant returns (uint _count);


}
