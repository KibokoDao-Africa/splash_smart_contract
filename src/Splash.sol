// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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

    // function multiEnroll(
    //     EnrollRequest[] memory requests
    // ) external returns (uint256[] memory);

    function updateEnrollment(
        uint256 enrollmentId,
        uint256 completedAt
    ) external;

    function enrollers(
        uint256 courseId
    ) external view returns (address[] memory);

    function enrolled(
        address student
    ) external view returns (Enrollment[] memory);

    function stake(uint256 enrollmentId, uint256 amount, bool agree) external;

    function disburse(uint256 enrollmentId) external;
}

contract Splash is ISplash {
    address public defaultAdmin;

    uint256 courseId;
    uint256 enrollmentId;
    mapping(uint256 => Course) public courses;
    mapping(uint256 => Enrollment) public enrollments;
    mapping(uint256 => Pool) public pools;
    // mapping(enrollmentId => mapping(address => uint256)) public stakes;
    mapping(uint256 => mapping(address => uint256)) public stakes;

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
    }

    function updateCourse(
        uint256 _courseId,
        string memory title,
        string memory description,
        string memory category
    ) external override onlyAdmin {
        require(
            courses[_courseId].creator == msg.sender,
            "Splash: not creator"
        );
        courses[_courseId].title = title;
        courses[_courseId].description = description;
        courses[_courseId].category = category;
    }

    function deleteCourse(uint256 _courseId) external override onlyAdmin {
        require(courses[courseId].creator == msg.sender, "Splash: not creator");
        delete courses[courseId];
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
    }

    // function multiEnroll(
    //     EnrollRequest[] memory requests
    // ) external override returns (uint256[] memory) {
    //     uint256[] memory enrollmentIds = new uint256[](requests.length);
    //     for (uint256 i = 0; i < requests.length; i++) {
    //         enrollmentIds[i] = enroll(requests[i]);
    //     }
    //     return enrollmentIds;
    // }

    function updateEnrollment(
        uint256 id,
        uint256 completedAt
    ) external override onlyAdmin {
        enrollments[enrollmentId].completedAt = completedAt;
    }

    function enrollers(
        uint256 _courseId
    ) external view override returns (address[] memory) {
        address[] memory students = new address[](enrollmentId);
        uint256 count = 0;
        for (uint256 i = 0; i < enrollmentId; i++) {
            if (enrollments[i].courseId == _courseId) {
                students[count++] = enrollments[i].student;
            }
        }
        return students;
    }

    function enrolled(
        address student
    ) external view override returns (Enrollment[] memory) {
        Enrollment[] memory studentEnrollments = new Enrollment[](enrollmentId);
        uint256 count = 0;
        for (uint256 i = 0; i < enrollmentId; i++) {
            if (enrollments[i].student == student) {
                studentEnrollments[count++] = enrollments[i];
            }
        }
        return studentEnrollments;
    }

    function stake(
        uint256 _enrollmentId,
        uint256 amount,
        bool agree
    ) external override {
        require(
            enrollments[_enrollmentId].completeBefore > block.timestamp,
            "Splash: course expired"
        );

        Pool storage pool = pools[_enrollmentId];

        // TODO:  keep track of stakes
        // TODO: tansfer amount to contract

        if (agree) {
            pool.against += amount;
        } else {
            pool.support += amount;
        }
    }

    function disburse(uint256 _enrollmentId) external override {
        Pool storage pool = pools[_enrollmentId];
        require(!pool.disbursed, "Splash: already disbursed");

        pool.disbursed = true;

        // TODO: calculate rewards based on staked amount per user
        // TODO: transfer rewards to winners

        pool.disbursed = true;
    }
}
