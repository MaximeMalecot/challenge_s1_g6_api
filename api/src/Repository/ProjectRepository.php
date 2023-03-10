<?php

namespace App\Repository;

use App\Entity\User;
use App\Entity\Project;
use Doctrine\Persistence\ManagerRegistry;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;

/**
 * @extends ServiceEntityRepository<Project>
 *
 * @method Project|null find($id, $lockMode = null, $lockVersion = null)
 * @method Project|null findOneBy(array $criteria, array $orderBy = null)
 * @method Project[]    findAll()
 * @method Project[]    findBy(array $criteria, array $orderBy = null, $limit = null, $offset = null)
 */
class ProjectRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Project::class);
    }

    public function add(Project $entity, bool $flush = false): void
    {
        $this->getEntityManager()->persist($entity);

        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }

    public function remove(Project $entity, bool $flush = false): void
    {
        $this->getEntityManager()->remove($entity);

        if ($flush) {
            $this->getEntityManager()->flush();
        }
    }

//    /**
//     * @return Project[] Returns an array of Project objects
//     */
//    public function findByExampleField($value): array
//    {
//        return $this->createQueryBuilder('p')
//            ->andWhere('p.exampleField = :val')
//            ->setParameter('val', $value)
//            ->orderBy('p.id', 'ASC')
//            ->setMaxResults(10)
//            ->getQuery()
//            ->getResult()
//        ;
//    }

//    public function findOneBySomeField($value): ?Project
//    {
//        return $this->createQueryBuilder('p')
//            ->andWhere('p.exampleField = :val')
//            ->setParameter('val', $value)
//            ->getQuery()
//            ->getOneOrNullResult()
//        ;
//    }
    public function hasCommonVerifiedProject(User $client, User $freelancer){
        $qb = $this->createQueryBuilder("p");
        $v = $qb->where("p.owner = :cId")
            ->innerJoin("p.propositions", "pr")
            ->andWhere("pr.freelancer = :fId" )
            ->andWhere("pr.status = 'ACCEPTED'")
            ->setParameters([ 
                "cId" => $client->getId(),
                "fId" => $freelancer->getId()
            ])
            ->getQuery()
            ->getResult();
        if(count($v) > 0){
            return true;
        }
        return false;
    }

    public function hasCommonProject(User $client, User $freelancer){
        $qb = $this->createQueryBuilder("p");
        $v = $qb->where("p.owner = :cId")
            ->innerJoin("p.propositions", "pr")
            ->andWhere("pr.freelancer = :fId" )
            ->setParameters([ 
                "cId" => $client->getId(),
                "fId" => $freelancer->getId()
            ])
            ->getQuery()
            ->getResult();
        if(count($v) > 0){
            return true;
        }
        return false;
    }

    public function hasCommonPastProject(User $client, User $freelancer){
        $qb = $this->createQueryBuilder("p");
        $v = $qb->where("p.owner = :cId")
            ->innerJoin("p.propositions", "pr")
            ->andWhere("pr.freelancer = :fId" )
            ->andWhere("pr.status = 'ACCEPTED'")
            ->andWhere("p.status = 'ENDED'")
            ->setParameters([ 
                "cId" => $client->getId(),
                "fId" => $freelancer->getId()
            ])
            ->getQuery()
            ->getResult();
        if(count($v) > 0){
            return true;
        }
        return false;

    }

    public function isOnProject(User $freelancer, Project $projet){
        $qb = $this->createQueryBuilder("p");
        $v = $qb->where("p = :pId")
            ->innerJoin("p.propositions", "pr")
            ->andWhere("pr.freelancer = :fId" )
            ->andWhere("pr.status = 'ACCEPTED'")
            ->setParameters([ 
                "pId" => $projet->getId(),
                "fId" => $freelancer->getId()
            ])
            ->getQuery()
            ->getResult();
        if(count($v) > 0){
            return true;
        }
        return false;
    }

    public function getFreelancerProjects(User $user, array $status=null){
        $qb = $this->createQueryBuilder("p");
        $qb->innerJoin("p.propositions", "pr")
            ->andWhere("pr.freelancer = :fId" )
            ->andWhere("pr.status = 'ACCEPTED'")
            ->setParameters([ 
                "fId" => $user->getId()
            ]);
        if($status != null){
            $qb->andWhere("p.status IN (:status)")
                ->setParameter("status", $status);
        }
        return $qb->getQuery()->getResult();
    }
}
