// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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
    address public defaultAdmin;
    uint256 private courseId;
    uint256 private enrollmentId;
    mapping(uint256 => Course) public courses;
    mapping(uint256 => Enrollment) public enrollments;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(address => uint256)) public stakes;
    mapping(uint256 => address[]) private courseEnrollers;

    event CourseCreated(uint256 indexed courseId, string title, address creator);
    event CourseUpdated(uint256 indexed courseId, string title);
    event CourseDeleted(uint256 indexed courseId);
    event EnrollmentCreated(uint256 indexed enrollmentId, uint256 courseId, address student);
    event EnrollmentUpdated(uint256 indexed enrollmentId, uint256 completedAt);
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
    ) external onlyAdmin returns (uint256 id) {
        id = courseId++;
        courses[id] = Course(id, title, description, category, msg.sender);
        emit CourseCreated(id, title, msg.sender);
    }

    function updateCourse(
        uint256 _courseId,
        string memory title,
        string memory description,
        string memory category
    ) external onlyAdmin {
        require(bytes(courses[_courseId].title).length != 0, "Course does not exist");
        courses[_courseId] = Course(_courseId, title, description, category, msg.sender);
        emit CourseUpdated(_courseId, title);
    }

    function deleteCourse(uint256 _courseId) external onlyAdmin {
        require(bytes(courses[_courseId].title).length != 0, "Course does not exist");
        delete courses[_courseId];
        emit CourseDeleted(_courseId);
    }

    function enroll(EnrollRequest memory request) external returns (uint256 id) {
        id = enrollmentId++;
        enrollments[id] = Enrollment(
            id,
            request.courseId,
            request.student,
            block.timestamp,
            0,
            request.completeBefore
        );
        courseEnrollers[request.courseId].push(request.student);
        emit EnrollmentCreated(id, request.courseId, request.student);
    }

    function updateEnrollment(uint256 _enrollmentId, uint256 _completedAt) external onlyAdmin {
        enrollments[_enrollmentId].completedAt = _completedAt;
        emit EnrollmentUpdated(_enrollmentId, _completedAt);
    }

    function enrollers(uint256 _courseId) external view returns (address[] memory) {
        return courseEnrollers[_courseId];
    }

    function enrolled(address student) external view returns (Enrollment[] memory) {
        Enrollment[] memory result = new Enrollment[](enrollmentId);
        uint count = 0;
        for (uint i = 0; i < enrollmentId; i++) {
            if (enrollments[i].student == student) {
                result[count] = enrollments[i];
                count++;
            }
        }
        return result;
    }

    function stake(uint256 _enrollmentId, uint256 amount, bool agree) external {
        require(enrollments[_enrollmentId].completeBefore > block.timestamp, "Splash: course expired");
        Pool storage pool = pools[_enrollmentId];
        stakes[_enrollmentId][msg.sender] += amount;
        if (agree) {
            pool.support += amount;
        } else {
            pool.against += amount;
        }
        emit Staked(msg.sender, _enrollmentId, amount, agree);
    }

    function disburse(uint256 _enrollmentId) external nonReentrant {
        Pool storage pool = pools[_enrollmentId];
        require(!pool.disbursed, "Splash: already disbursed");
        require(enrollments[_enrollmentId].completedAt > 0, "Splash: not completed");
        uint256 totalPool = pool.support + pool.against;
        uint256 fee = (totalPool * 10) / 100;
        uint256 rewardPool = totalPool - fee;
        for (uint256 i = 0; i < enrollmentId; i++) {
            address staker = enrollments[i].student;
            uint256 stakedAmount = stakes[_enrollmentId][staker];
            uint256 reward = (stakedAmount * rewardPool) / totalPool;
            payable(staker).transfer(reward);
        }
        pool.disbursed = true;
        emit Disbursed(_enrollmentId, rewardPool);
    }

    function batchTransfer(address[] calldata _recipients, uint256[] calldata _amounts) external payable {
        require(_recipients.length == _amounts.length, "Arrays length mismatch");
        for (uint256 i = 0; i < _recipients.length; i++) {
            payable(_recipients[i]).transfer(_amounts[i]);
        }
    }

    receive() external payable {}
}
