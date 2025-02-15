// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
interface ISplash {
    struct Course {
        uint256 id;
        string title;
        string description;
        string category;
        address creator;
    }

    struct Enrollment {
        uint256 id;
        uint256 courseId;
        address student;
        uint256 enrolledAt;
        uint256 completedAt;
        uint256 completeBefore;
    }

    struct EnrollRequest {
        uint256 courseId;
        uint256 completeBefore;
        address student;
        uint256 amount;
    }

    struct Pool {
        uint256 enrollmentId;
        uint256 against;
        uint256 support;
        bool disbursed;
    }

    function createCourse(
        string memory title,
        string memory description,
        string memory category
    ) external returns (uint256);

    function updateCourse(
        uint256 courseId,
        string memory title,
        string memory description,
        string memory category
    ) external;

    function deleteCourse(uint256 courseId) external;

    function enroll(EnrollRequest memory request) external returns (uint256);

    function updateEnrollment(
        uint256 enrollmentId,
        uint256 completedAt
    ) external;

    function enrollers(uint256 courseId) external view returns (address[] memory);
    function enrolled(address student) external view returns (Enrollment[] memory);
    function stake(uint256 enrollmentId, uint256 amount, bool agree) external;
    function disburse(uint256 enrollmentId) external;
    function batchTransfer(address[] calldata _recipients, uint256[] calldata _amounts) external payable;
}

contract Splash is ISplash, ReentrancyGuard {
    using SafeMath for uint256;

    address public defaultAdmin;
    uint256 private courseId;
    uint256 private enrollmentId;
    mapping(uint256 => Course) public courses;
    mapping(uint256 => Enrollment) public enrollments;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(address => uint256)) public stakes;

    event CourseCreated(uint256 indexed courseId, string title, address creator);
    event EnrollmentCreated(uint256 indexed enrollmentId, uint256 courseId, address student);
    event Staked(address indexed user, uint256 indexed enrollmentId, uint256 amount, bool agree);
    event Disbursed(uint256 indexed enrollmentId, uint256 rewardPool);

    constructor() {
        defaultAdmin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == defaultAdmin, "Splash: not admin");
        _;
    }

    function createCourse(
        string memory title,
        string memory description,
        string memory category
    ) external override onlyAdmin returns (uint256 id) {
        id = courseId++;
        courses[id] = Course(id, title, description, category, msg.sender);
        emit CourseCreated(id, title, msg.sender);
    }

    function enroll(
        EnrollRequest memory request
    ) external override returns (uint256 id) {
        id = enrollmentId++;
        enrollments[id] = Enrollment(
            id,
            request.courseId,
            request.student,
            block.timestamp,
            0,
            request.completeBefore
        );
        emit EnrollmentCreated(id, request.courseId, request.student);
    }

    function stake(
        uint256 _enrollmentId,
        uint256 amount,
        bool agree
    ) external override nonReentrant {
        require(
            enrollments[_enrollmentId].completeBefore > block.timestamp,
            "Splash: course expired"
        );
        
        Pool storage pool = pools[_enrollmentId];
        stakes[_enrollmentId][msg.sender] = stakes[_enrollmentId][msg.sender].add(amount);

        if (agree) {
            pool.support = pool.support.add(amount);
        } else {
            pool.against = pool.against.add(amount);
        }

        emit Staked(msg.sender, _enrollmentId, amount, agree);
    }

    function disburse(uint256 _enrollmentId) external override nonReentrant {
        Pool storage pool = pools[_enrollmentId];
        require(!pool.disbursed, "Splash: already disbursed");
        require(enrollments[_enrollmentId].completedAt > 0, "Splash: not completed");

        uint256 totalPool = pool.support.add(pool.against);
        uint256 fee = totalPool.mul(10).div(100);
        uint256 rewardPool = totalPool.sub(fee);

        for (uint256 i = 0; i < enrollmentId; i++) {
            address staker = enrollments[i].student;
            uint256 stakedAmount = stakes[_enrollmentId][staker];
            uint256 reward = (stakedAmount.mul(rewardPool)).div(totalPool);
            payable(staker).transfer(reward);
        }

        pool.disbursed = true;
        emit Disbursed(_enrollmentId, rewardPool);
    }

    function batchTransfer(address[] calldata _recipients, uint256[] calldata _amounts) external payable override nonReentrant {
        require(_recipients.length == _amounts.length, "Arrays length mismatch");
        for (uint256 i = 0; i < _recipients.length; i++) {
            payable(_recipients[i]).transfer(_amounts[i]);
        }
    }

    receive() external payable {}
}
